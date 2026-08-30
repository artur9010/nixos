#!/usr/bin/env python3
"""Bridge Logitech battery readings to virtual HID batteries via /dev/uhid.

Speaks the HID++ protocol directly over /dev/hidraw (no Solaar dependency),
mirroring how Solaar itself queries batteries:
  - receivers (Bolt/Unifying/Nano/Lightspeed): ping device slots, then
    HID++ 2.0 battery features (0x1000 / 0x1001 / 0x1004), falling back to
    HID++ 1.0 battery registers (0x07 / 0x0D) for old peripherals
  - Bluetooth/wired Logitech devices: same queries with device index 0xFF

Each device that reports a battery gets a virtual uhid device whose report
descriptor carries HID Battery System usages (page 0x85):
  - 0x44 Charging               (1 byte, 0 = discharging, 1 = charging)
  - 0x65 Absolute State of Charge (1 byte, 0-100)
The kernel turns these into a power_supply class device, which UPower and the
KDE Power and Battery applet pick up automatically.

Runs as root (needs /dev/uhid and the hidraw devices of the receivers).

Protocol reference: Solaar lib/logitech_receiver/{base,hidpp10,hidpp20,
base_usb}.py (GPL-2+) and Logitech HID++ documentation at
https://github.com/Logitech/cpg-docs/tree/master/hidpp20
"""

import argparse
import ctypes
import logging
import os
import re
import select
import signal
import struct
import sys
import time

UHID_DESTROY = 1
UHID_START = 2
UHID_GET_REPORT = 8
UHID_CREATE2 = 11
UHID_INPUT2 = 12
UHID_GET_REPORT_REPLY = 9

BUS_USB = 0x03

HID_MAX_DESCRIPTOR_SIZE = 4096
UHID_DATA_MAX = 4096

# ---------------------------------------------------------------------------
# HID++ over hidraw
# ---------------------------------------------------------------------------

LOGITECH_VENDOR_ID = 0x046D
LENOVO_VENDOR_ID = 0x17F7  # one rebranded Nano receiver

# HID_PHYS stamped on the uhid devices this script creates; also used to
# recognise (and skip) them during discovery.
UHID_PHYS = "logitech-battery-uhid"

# Our HID++ Software ID. The high bit stays set so replies remain
# distinguishable from notifications. Known users: 0x07 OpenRGB, 0x0A
# LGSTrayEx, 0x0B Solaar, 0x0D G HUB, 0x0F device firmware.
SOFTWARE_ID = 0x0C

REPORT_ID_SHORT = 0x10
REPORT_ID_LONG = 0x11
SHORT_FRAME = 7   # report id + device index + 2-byte request + 3 params
LONG_FRAME = 20   # report id + device index + 2-byte request + 16 params

# Reply payload prefixes that mark an error instead of a normal reply.
HIDPP10_ERR = 0x8F
HIDPP20_ERR = 0xFF

# HID++ 1.0 error codes (Solaar hidpp10_constants.ErrorCode)
ERR10_INVALID_SUB_ID = 0x01
ERR10_UNKNOWN_DEVICE = 0x08

RECEIVER_TIMEOUT = 2.0   # receiver itself answers fast
DEVICE_TIMEOUT = 4.0     # wireless round trip to a peripheral
PING_TIMEOUT = 4.0

# {0x1000: function index}: battery features, tried in Solaar's order
# (lib/logitech_receiver/hidpp20.py battery_functions).
FEAT_BATTERY_STATUS = 0x1000
FEAT_BATTERY_VOLTAGE = 0x1001
FEAT_UNIFIED_BATTERY = 0x1004
FEAT_DEVICE_NAME = 0x0005

# BatteryStatus values (Solaar common.BatteryStatus)
STATUS_DISCHARGING = 0x00
STATUS_RECHARGING = 0x01
STATUS_FULL = 0x03
STATUS_SLOW_RECHARGE = 0x04
CHARGING_STATUSES = (STATUS_RECHARGING, 0x02, STATUS_FULL, STATUS_SLOW_RECHARGE)

# Voltage (mV) -> percent, linearly interpolated between points
# (Solaar hidpp20.estimate_battery_level_percentage).
VOLTAGE_TO_PERCENT = [
    (4186, 100), (4067, 90), (3989, 80), (3922, 70), (3859, 60),
    (3811, 50), (3778, 40), (3751, 30), (3717, 20), (3671, 10),
    (3646, 5), (3579, 2), (3500, 0),
]

# Unified battery coarse level -> percent
# (Solaar common.BatteryLevelApproximation).
LEVEL_TO_PERCENT = {8: 90, 4: 50, 2: 20, 1: 5, 0: 0}

# USB product id -> (name, kind, usb interface carrying HID++, max devices)
# (Solaar base_usb.KNOWN_RECEIVERS; interface numbers matter: Bolt/Unifying/
# Lightspeed receivers expose HID++ on USB interface 2, Nano on 1).
KNOWN_RECEIVERS = {
    0xC548: ("Bolt Receiver", "bolt", 2, 6),
    0xC52B: ("Unifying Receiver", "unifying", 2, 6),
    0xC532: ("Unifying Receiver", "unifying", 2, 6),
    0xC517: ("EX100 Receiver 27 Mhz", "27mhz", 1, 4),
    0xC518: ("Nano Receiver", "nano", 1, 1),
    0xC51A: ("Nano Receiver", "nano", 1, 1),
    0xC51B: ("Nano Receiver", "nano", 1, 1),
    0xC521: ("Nano Receiver", "nano", 1, 1),
    0xC525: ("Nano Receiver", "nano", 1, 1),
    0xC526: ("Nano Receiver", "nano", 1, 1),
    0xC52E: ("Nano Receiver", "nano", 1, 1),
    0xC52F: ("Nano Receiver", "nano", 1, 1),
    0xC531: ("Nano Receiver", "nano", 1, 1),
    0xC534: ("Nano Receiver", "nano", 1, 2),
    0xC535: ("Nano Receiver", "nano", 1, 1),
    0xC537: ("Nano Receiver", "nano", 1, 1),
    0xC539: ("Lightspeed Receiver", "lightspeed", 2, 2),
    0xC53A: ("Lightspeed Receiver", "lightspeed", 2, 2),
    0xC53D: ("Lightspeed Receiver", "lightspeed", 2, 2),
    0xC53F: ("Lightspeed Receiver", "lightspeed", 2, 2),
    0xC541: ("Lightspeed Receiver", "lightspeed", 2, 2),
    0xC545: ("Lightspeed Receiver", "lightspeed", 2, 2),
    0xC547: ("Lightspeed Receiver", "lightspeed", 2, 2),
    0xC54D: ("Lightspeed Receiver", "lightspeed", 2, 2),
}

# Wired USB product id ranges of HID++-capable devices
# (Solaar base_usb module docstring).
WIRED_PID_RANGES = ((0xC07D, 0xC094), (0xC32B, 0xC344))

USB_IFACE_RE = re.compile(r"^\d+-[^/]*:\d+\.(\d+)$")
HID_DEVICE_RE = re.compile(r"^\d{4}:[0-9A-Fa-f]{8}:[0-9A-Fa-f]{8}\.\d{4}$")


class HidppError(Exception):
    """The device answered with a HID++ error report."""

    def __init__(self, request, code):
        super().__init__("HID++ error %02X on request %04X" % (code, request))
        self.request = request
        self.code = code


class HidppBus:
    """HID++ request/response over a single hidraw node."""

    def __init__(self, path):
        self.path = path
        self.fd = os.open(path, os.O_RDWR | os.O_CLOEXEC)

    def close(self):
        try:
            os.close(self.fd)
        except OSError:
            pass

    def _read_frame(self, timeout):
        """Read one frame, skip everything that is not a HID++ report."""
        readable, _, _ = select.select([self.fd], [], [], timeout)
        if not readable:
            return None
        try:
            data = os.read(self.fd, 32)
        except OSError:
            raise
        if not data:
            raise OSError("device disconnected: %s" % self.path)
        report_id = data[0]
        if report_id == REPORT_ID_SHORT and len(data) >= SHORT_FRAME:
            return data[:SHORT_FRAME]
        if report_id == REPORT_ID_LONG and len(data) >= LONG_FRAME:
            return data[:LONG_FRAME]
        return None  # input reports, DJ records, notifications-shaped noise

    def _drain(self):
        while True:
            try:
                if not select.select([self.fd], [], [], 0)[0]:
                    return
                if not os.read(self.fd, 512):
                    raise OSError("device disconnected: %s" % self.path)
            except BlockingIOError:
                return

    def request(self, devnumber, request_id, params=b"", long=False, timeout=DEVICE_TIMEOUT):
        """Send a request, return the reply payload without the request echo.

        Raises HidppError on a HID++ error reply, returns None on timeout.
        """
        payload = struct.pack("!H", request_id) + params
        # Same length rule as Solaar base.write(): payload over 5 bytes or an
        # 0x82-prefixed long register access must go out as a long report.
        if long or len(payload) > 5 or payload[:1] == b"\x82":
            frame = bytes([REPORT_ID_LONG, devnumber]) + payload[:16]
            frame = frame.ljust(LONG_FRAME, b"\x00")
        else:
            frame = bytes([REPORT_ID_SHORT, devnumber]) + payload[:5]
            frame = frame.ljust(SHORT_FRAME, b"\x00")

        self._drain()
        logging.debug("%s <= [%s]", self.path, frame.hex(" "))
        os.write(self.fd, frame)

        deadline = time.monotonic() + timeout
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                logging.debug("timeout on dev %d request %04X", devnumber, request_id)
                return None
            frame = self._read_frame(remaining)
            if frame is None:
                continue
            rid, dev = frame[0], frame[1]
            body = frame[2:]
            if dev != devnumber and dev != (devnumber ^ 0xFF):
                continue  # BT devices answer with device index 0x00
            logging.debug("%s => [%s]", self.path, frame.hex(" "))
            if body[0] in (HIDPP10_ERR, HIDPP20_ERR) and body[1:3] == payload[:2]:
                raise HidppError(request_id, body[2])
            if body[:2] == payload[:2]:
                # Receiver register replies echo the subregister as well
                if request_id & 0xFF00 == 0x8300 and body[2:3] != params[:1]:
                    continue
                return body[2:]

    def ping(self, devnumber, long=False):
        """Return the HID++ protocol version (e.g. 4.5), 1.0 for HID++ 1.0
        devices, or None when the device does not answer."""
        mark = os.urandom(1)[0] or 0x5A
        request_id = 0x0010 | SOFTWARE_ID
        try:
            reply = self.request(devnumber, request_id, bytes([0, 0, mark]), long=long, timeout=PING_TIMEOUT)
        except HidppError as exc:
            if exc.code == ERR10_INVALID_SUB_ID:
                return 1.0  # valid answer from a HID++ 1.0 device
            if exc.code == ERR10_UNKNOWN_DEVICE:
                return None
            return None  # resource/connection errors: device unreachable
        if reply and len(reply) >= 3 and reply[2] == mark:
            return reply[0] + reply[1] / 10.0
        return None

    # -- HID++ 2.0 helpers -------------------------------------------------

    def get_feature_index(self, devnumber, feature_id, long):
        """Root.GetFeature: returns the feature index, 0 if unsupported."""
        request_id = SOFTWARE_ID  # feature 0 (root), function 0
        reply = self.request(devnumber, request_id, struct.pack("!H", feature_id), long=long)
        if not reply:
            return 0
        return reply[0]

    def feature_call(self, devnumber, feature_index, function, params=b"", long=False):
        request_id = (feature_index << 8) | (function << 4) | SOFTWARE_ID
        return self.request(devnumber, request_id, params, long=long)

    def device_name(self, devnumber, long):
        idx = self.get_feature_index(devnumber, FEAT_DEVICE_NAME, long)
        if not idx:
            return None
        reply = self.feature_call(devnumber, idx, 0)
        if not reply:
            return None
        length = reply[0]
        name = b""
        while len(name) < length:
            fragment = self.feature_call(devnumber, idx, 1, bytes([len(name)]))
            if not fragment:
                return None
            name += fragment[: length - len(name)]
        return name.decode("utf-8", "replace")


def voltage_to_percent(voltage_mv):
    if voltage_mv >= VOLTAGE_TO_PERCENT[0][0]:
        return 100
    if voltage_mv <= VOLTAGE_TO_PERCENT[-1][0]:
        return 0
    for (v_high, p_high), (v_low, p_low) in zip(VOLTAGE_TO_PERCENT, VOLTAGE_TO_PERCENT[1:]):
        if v_low <= voltage_mv <= v_high:
            return round(p_low + (p_high - p_low) * (voltage_mv - v_low) / (v_high - v_low))
    return 0


def query_battery_hidpp20(bus, devnumber, long):
    """Returns (percent or None, charging) using the first supported feature."""
    # BATTERY_STATUS (0x1000): [current %, next %, status]
    idx = bus.get_feature_index(devnumber, FEAT_BATTERY_STATUS, long)
    if idx:
        reply = bus.feature_call(devnumber, idx, 0)
        if reply and len(reply) >= 3:
            percent = reply[0] or None
            return percent, reply[2] in CHARGING_STATUSES

    # BATTERY_VOLTAGE (0x1001): [voltage mV BE, flags]
    idx = bus.get_feature_index(devnumber, FEAT_BATTERY_VOLTAGE, long)
    if idx:
        reply = bus.feature_call(devnumber, idx, 0)
        if reply and len(reply) >= 3:
            voltage = (reply[0] << 8) | reply[1]
            flags = reply[2]
            charging = bool(flags & 0x80) and not ((flags & 0x03) == 0x02)
            return voltage_to_percent(voltage), charging

    # UNIFIED_BATTERY (0x1004) function 1: [discharge %, level, status]
    idx = bus.get_feature_index(devnumber, FEAT_UNIFIED_BATTERY, long)
    if idx:
        reply = bus.feature_call(devnumber, idx, 1)
        if reply and len(reply) >= 3:
            percent = reply[0] or LEVEL_TO_PERCENT.get(reply[1])
            return percent, reply[2] in CHARGING_STATUSES

    return None, False


def query_battery_hidpp10(bus, devnumber):
    """HID++ 1.0 battery registers, in Solaar's try order."""
    # BATTERY_CHARGE (0x0D): [percent, ?, status nibble in high bits]
    try:
        reply = bus.request(devnumber, 0x810D)
        if reply and len(reply) >= 3:
            status = reply[2] & 0xF0
            return reply[0], status in (0x50, 0x90)
    except HidppError:
        pass
    # BATTERY_STATUS (0x07): [coarse level, charging flags]
    try:
        reply = bus.request(devnumber, 0x8107)
    except HidppError:
        return None, False
    if not reply or len(reply) < 2:
        return None, False
    status_byte, charging_byte = reply[0], reply[1]
    percent = {7: 90, 5: 50, 3: 20, 1: 5}.get(status_byte)
    charging = (charging_byte & 0x21) == 0x21 or (charging_byte & 0x22) == 0x22
    if charging_byte & 0x03 and status_byte == 0:
        percent = None  # charging notification without level information
    return percent, charging


# ---------------------------------------------------------------------------
# Device discovery via sysfs
# ---------------------------------------------------------------------------

def read_uevent(device_dir):
    props = {}
    try:
        with open(os.path.join(device_dir, "uevent"), "r") as f:
            for line in f:
                key, _, value = line.strip().partition("=")
                props[key] = value
    except OSError:
        pass
    return props


def hidraw_devices():
    """Yield dicts describing each hidraw node's HID parent."""
    base = "/sys/class/hidraw"
    try:
        entries = os.listdir(base)
    except OSError:
        return
    for entry in sorted(entries):
        link = os.path.join(base, entry)
        try:
            device_dir = os.path.realpath(os.path.join(link, "device"))
            parent_dir = os.path.dirname(device_dir)
        except OSError:
            continue
        props = read_uevent(device_dir)
        hid_id = props.get("HID_ID", "")
        parts = hid_id.split(":")
        if len(parts) != 3:
            continue
        try:
            bus, vid, pid = (int(p, 16) for p in parts)
        except ValueError:
            continue
        yield {
            "node": os.path.join("/dev", entry),
            "bus": bus,
            "vid": vid,
            "pid": pid,
            "name": props.get("HID_NAME", "Logitech device"),
            "uniq": props.get("HID_UNIQ", ""),
            "phys": props.get("HID_PHYS", ""),
            "dir": device_dir,
            "parent": os.path.basename(parent_dir),
        }


def usb_interface_number(info):
    match = USB_IFACE_RE.match(info["parent"])
    return int(match.group(1)) if match else None


def is_receiver(info):
    """Return (name, kind, max_devices) when the node is a receiver's HID++
    interface, else None."""
    if info["vid"] != LOGITECH_VENDOR_ID or info["pid"] not in KNOWN_RECEIVERS:
        return None
    name, kind, iface, max_devices = KNOWN_RECEIVERS[info["pid"]]
    if usb_interface_number(info) != iface:
        return None
    return name, kind, max_devices


def is_wired_hidpp(info):
    if info["vid"] != LOGITECH_VENDOR_ID or info["bus"] != 3:
        return False
    if info["pid"] in KNOWN_RECEIVERS:
        return False
    # Skip nodes the kernel created for receiver-attached peripherals
    if HID_DEVICE_RE.match(info["parent"]):
        return False
    # Skip the uhid devices this script creates
    if info["phys"] == UHID_PHYS:
        return False
    return any(lo <= info["pid"] <= hi for lo, hi in WIRED_PID_RANGES)


def is_bluetooth_hidpp(info):
    return info["bus"] == 5 and info["vid"] == LOGITECH_VENDOR_ID and info["phys"] != UHID_PHYS


def receiver_slot_serial(bus, kind, index):
    """Read the pairing register to get a stable serial for a slot.

    Returns the serial string, or None when the reply does not parse.
    Raises HidppError / returns None on timeout for empty slots.
    """
    if kind == "bolt":
        # RECEIVER_INFO (0x2B5) subregister 0x50 + index:
        # [sub, kind/status, wpid LE, serial BE (4 bytes)]
        reply = bus.request(0xFF, 0x83B5, bytes([0x50 + index]), timeout=RECEIVER_TIMEOUT)
        if reply and len(reply) >= 8:
            return reply[4:8].hex().upper()
        return None
    # Unifying-style: PAIRING_INFORMATION 0x20 + index - 1 proves the slot,
    # EXTENDED_PAIRING_INFORMATION 0x30 + index - 1 carries the serial.
    reply = bus.request(0xFF, 0x83B5, bytes([0x20 + index - 1]), timeout=RECEIVER_TIMEOUT)
    if not reply or len(reply) < 8:
        return None
    try:
        ext = bus.request(0xFF, 0x83B5, bytes([0x30 + index - 1]), timeout=RECEIVER_TIMEOUT)
    except HidppError:
        ext = None
    if ext and len(ext) >= 5:
        return ext[1:5].hex().upper()
    return reply[3:5].hex().upper()


# ---------------------------------------------------------------------------
# Scanning
# ---------------------------------------------------------------------------

# Serial -> device name, so the DEVICE_NAME feature is queried only once
DEVICE_NAMES = {}

def query_direct_device(bus, info, bluetooth):
    """Poll a directly connected (BT or wired) device. Returns None when it
    does not answer."""
    if bluetooth:
        protocol = bus.ping(0xFF, long=True)
    else:
        protocol = bus.ping(0xFF, long=False) or bus.ping(0xFF, long=True)
    if protocol is None:
        return None
    serial = info["uniq"] or info["node"]
    long = bluetooth or protocol >= 2.0
    name = cached_device_name(serial, bus, 0xFF, long, protocol, info["name"])
    if protocol >= 2.0:
        percent, charging = query_battery_hidpp20(bus, 0xFF, long)
    else:
        percent, charging = query_battery_hidpp10(bus, 0xFF)
    return serial, name, percent, charging


def cached_device_name(serial, bus, devnumber, long, protocol, fallback):
    name = DEVICE_NAMES.get(serial)
    if name is not None:
        return name
    if protocol >= 2.0:
        try:
            name = bus.device_name(devnumber, long)
        except HidppError:
            name = None
    DEVICE_NAMES[serial] = name or fallback
    return DEVICE_NAMES[serial]


def query_receiver(bus, kind, max_devices):
    """Poll all slots of a receiver. Yields (serial, name, percent, charging)."""
    for index in range(1, max_devices + 1):
        try:
            serial = receiver_slot_serial(bus, kind, index)
        except HidppError:
            continue  # empty slot
        if serial is None:
            # Slot pairing info unreadable (some Nano receivers): still try
            # to ping slot 1 directly.
            if kind != "nano" or index != 1:
                continue
            serial = "slot1"
        protocol = bus.ping(index)
        if protocol is None:
            continue  # paired but currently offline
        try:
            name = cached_device_name(serial, bus, index, protocol >= 2.0, protocol, "Logitech device")
            if protocol >= 2.0:
                percent, charging = query_battery_hidpp20(bus, index, True)
            else:
                percent, charging = query_battery_hidpp10(bus, index)
        except HidppError as exc:
            logging.debug("slot %d battery query failed: %s", index, exc)
            continue
        yield serial, name, percent, charging


def scan():
    """Query every HID++ device found. Returns {serial: (name, percent, charging)}."""
    devices = {}
    for info in hidraw_devices():
        receiver = is_receiver(info)
        try:
            if receiver:
                name, kind, max_devices = receiver
                logging.debug("receiver %s at %s (%s)", name, info["node"], kind)
                bus = HidppBus(info["node"])
                try:
                    for serial, dev_name, percent, charging in query_receiver(bus, kind, max_devices):
                        devices[serial] = (dev_name, percent, charging)
                finally:
                    bus.close()
            elif is_bluetooth_hidpp(info):
                logging.debug("bluetooth device %s at %s", info["name"], info["node"])
                bus = HidppBus(info["node"])
                try:
                    result = query_direct_device(bus, info, bluetooth=True)
                finally:
                    bus.close()
                if result:
                    serial, dev_name, percent, charging = result
                    devices[serial] = (dev_name, percent, charging)
            elif is_wired_hidpp(info):
                logging.debug("wired device %s at %s", info["name"], info["node"])
                bus = HidppBus(info["node"])
                try:
                    result = query_direct_device(bus, info, bluetooth=False)
                finally:
                    bus.close()
                if result:
                    serial, dev_name, percent, charging = result
                    devices[serial] = (dev_name, percent, charging)
        except (OSError, HidppError) as exc:
            logging.debug("skipping %s: %s", info["node"], exc)

    # Drop entries without a usable percentage
    return {s: v for s, v in devices.items() if v[1] is not None}


# ---------------------------------------------------------------------------
# uhid virtual batteries (unchanged behaviour)
# ---------------------------------------------------------------------------

# The kernel (drivers/hid/hid-input.c) only wires up an HID battery when the
# device passes IS_INPUT_APPLICATION(); a Mouse application qualifies.
# Real mouse bits (buttons 1-3 + REL_X/Y) are required for two reasons:
# 1. battery (EV_PWR) usages alone leave the input device "unpopulated",
#    which makes hidinput_connect() unwind and stops all report processing;
# 2. udev's input_id tags the input node ID_INPUT_MOUSE=1 only for mouse
#    buttons + relative axes, and UPower derives the battery kind (mouse)
#    from that sibling tag. Buttons map to BTN_LEFT.. only under a
#    Mouse/Pointer application, not under Consumer Control.
# Input report layout (5 bytes):
#   [0] charging (0/1)          usage 0x00850044
#   [1] percent (0-100)         usage 0x00850065
#   [2] buttons bit 0..2 + pad  (always 0)
#   [3] X relative (int8)       (always 0)
#   [4] Y relative (int8)       (always 0)
REPORT_DESCRIPTOR = bytes(
    [
        0x05, 0x01,          # Usage Page (Generic Desktop)
        0x09, 0x02,          # Usage (Mouse)
        0xA1, 0x01,          # Collection (Application)
        0x05, 0x85,          #   Usage Page (Battery System)
        0x15, 0x00,          #   Logical Minimum (0)
        0x26, 0xFF, 0x00,    #   Logical Maximum (255)
        0x09, 0x44,          #   Usage (Charging)
        0x75, 0x08,          #   Report Size (8)
        0x95, 0x01,          #   Report Count (1)
        0x81, 0x02,          #   Input (Data, Var, Abs)
        0x15, 0x00,          #   Logical Minimum (0)
        0x25, 0x64,          #   Logical Maximum (100)
        0x09, 0x65,          #   Usage (Absolute State of Charge)
        0x75, 0x08,          #   Report Size (8)
        0x95, 0x01,          #   Report Count (1)
        0x81, 0x02,          #   Input (Data, Var, Abs)
        0x05, 0x09,          #   Usage Page (Button)
        0x19, 0x01,          #   Usage Minimum (Button 1)
        0x29, 0x03,          #   Usage Maximum (Button 3)
        0x15, 0x00,          #   Logical Minimum (0)
        0x25, 0x01,          #   Logical Maximum (1)
        0x75, 0x01,          #   Report Size (1)
        0x95, 0x03,          #   Report Count (3)
        0x81, 0x02,          #   Input (Data, Var, Abs)
        0x95, 0x05,          #   Report Count (5)
        0x81, 0x03,          #   Input (Const, Var, Abs) padding
        0x05, 0x01,          #   Usage Page (Generic Desktop)
        0x09, 0x30,          #   Usage (X)
        0x09, 0x31,          #   Usage (Y)
        0x15, 0x81,          #   Logical Minimum (-127)
        0x25, 0x7F,          #   Logical Maximum (127)
        0x75, 0x08,          #   Report Size (8)
        0x95, 0x02,          #   Report Count (2)
        0x81, 0x06,          #   Input (Data, Var, Rel)
        0xC0,                # End Collection
    ]
)
REPORT_SIZE = 5


class UhidCreate2Req(ctypes.Structure):
    _fields_ = [
        ("name", ctypes.c_uint8 * 128),
        ("phys", ctypes.c_uint8 * 64),
        ("uniq", ctypes.c_uint8 * 64),
        ("rd_size", ctypes.c_uint16),
        ("bus", ctypes.c_uint16),
        ("vendor", ctypes.c_uint32),
        ("product", ctypes.c_uint32),
        ("version", ctypes.c_uint32),
        ("country", ctypes.c_uint32),
        ("rd_data", ctypes.c_uint8 * HID_MAX_DESCRIPTOR_SIZE),
    ]


class UhidInput2Req(ctypes.Structure):
    _fields_ = [
        ("size", ctypes.c_uint16),
        ("data", ctypes.c_uint8 * UHID_DATA_MAX),
    ]


class UhidGetReportReq(ctypes.Structure):
    _fields_ = [
        ("id", ctypes.c_uint32),
        ("rnum", ctypes.c_uint8),
        ("rtype", ctypes.c_uint8),
    ]


class UhidGetReportReplyReq(ctypes.Structure):
    _fields_ = [
        ("id", ctypes.c_uint32),
        ("err", ctypes.c_uint16),
        ("size", ctypes.c_uint16),
        ("data", ctypes.c_uint8 * UHID_DATA_MAX),
    ]


class UhidEventUnion(ctypes.Union):
    _fields_ = [
        ("create2", UhidCreate2Req),
        ("input2", UhidInput2Req),
        ("get_report_reply", UhidGetReportReplyReq),
    ]


class UhidEvent(ctypes.Structure):
    _fields_ = [
        ("type", ctypes.c_uint32),
        ("u", UhidEventUnion),
    ]


class VirtualBattery:
    def __init__(self, uhid_path, name, uniq, percent, charging, vendor=0x046D, product=0xB034):
        self.name = name
        self.uniq = uniq
        self.report_state = bytearray(
            [1 if charging else 0, percent, 0, 0, 0]
        )
        self.fd = os.open(uhid_path, os.O_RDWR | os.O_NONBLOCK | os.O_CLOEXEC)
        event = UhidEvent()
        memset(event, 0)
        event.type = UHID_CREATE2
        create = event.u.create2
        create.name = bytes_field(name, 128)
        create.phys = bytes_field(UHID_PHYS, 64)
        create.uniq = bytes_field(uniq, 64)
        create.rd_size = len(REPORT_DESCRIPTOR)
        create.bus = BUS_USB
        create.vendor = vendor
        create.product = product
        create.version = 0
        create.country = 0
        create.rd_data = (ctypes.c_uint8 * HID_MAX_DESCRIPTOR_SIZE).from_buffer_copy(
            REPORT_DESCRIPTOR.ljust(HID_MAX_DESCRIPTOR_SIZE, b"\x00")
        )
        os.write(self.fd, event)
        self.wait_started(timeout=2.0)

    def wait_started(self, timeout):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            readable, _, _ = select.select([self.fd], [], [], max(0.0, deadline - time.monotonic()))
            if not readable:
                break
            try:
                raw = os.read(self.fd, ctypes.sizeof(UhidEvent))
            except BlockingIOError:
                break
            if len(raw) >= 4:
                etype = int.from_bytes(raw[:4], sys.byteorder)
                logging.debug("uhid %s: event %d", self.uniq, etype)
                if etype == UHID_GET_REPORT:
                    self.reply_get_report(raw)
                if etype == UHID_START:
                    return

    def update(self, percent, charging):
        self.report_state[0] = 1 if charging else 0
        self.report_state[1] = percent
        event = UhidEvent()
        memset(event, 0)
        event.type = UHID_INPUT2
        event.u.input2.size = REPORT_SIZE
        event.u.input2.data[0] = self.report_state[0]
        event.u.input2.data[1] = self.report_state[1]
        event.u.input2.data[2] = 0
        os.write(self.fd, event)
        self.drain()

    def reply_get_report(self, raw):
        """Answer kernel GET_REPORT with the current report state."""
        req = UhidGetReportReq.from_buffer_copy(
            raw[ctypes.sizeof(ctypes.c_uint32):ctypes.sizeof(ctypes.c_uint32) + ctypes.sizeof(UhidGetReportReq)]
        )
        reply = UhidEvent()
        memset(reply, 0)
        reply.type = UHID_GET_REPORT_REPLY
        rep = reply.u.get_report_reply
        rep.id = req.id
        rep.err = 0
        rep.size = REPORT_SIZE
        for i in range(REPORT_SIZE):
            rep.data[i] = self.report_state[i]
        os.write(self.fd, reply)

    def drain(self):
        header_size = ctypes.sizeof(ctypes.c_uint32)
        while True:
            try:
                raw = os.read(self.fd, ctypes.sizeof(UhidEvent))
            except BlockingIOError:
                return
            if len(raw) >= header_size:
                etype = int.from_bytes(raw[:4], sys.byteorder)
                if etype == UHID_GET_REPORT:
                    self.reply_get_report(raw)

    def destroy(self):
        try:
            event = UhidEvent()
            memset(event, 0)
            event.type = UHID_DESTROY
            os.write(self.fd, event)
        except OSError:
            pass
        try:
            os.close(self.fd)
        except OSError:
            pass

    def __del__(self):
        try:
            self.destroy()
        except Exception:
            pass


def memset(structure, value):
    ctypes.memmove(ctypes.addressof(structure), bytes([value]) * ctypes.sizeof(structure), ctypes.sizeof(structure))


def bytes_field(text, size):
    data = text.encode("utf-8")[: size - 1]
    field = (ctypes.c_uint8 * size)()
    field[: len(data)] = data
    return field


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--interval", type=int, default=60, help="polling interval in seconds")
    parser.add_argument("--uhid-device", default="/dev/uhid", help="path to the uhid device")
    parser.add_argument("--dry-run", action="store_true", help="log what would be done, touch no uhid device")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s %(message)s",
    )

    batteries = {}

    def shutdown(signum, frame):
        logging.info("shutting down")
        for key, battery in batteries.items():
            if not args.dry_run:
                battery.destroy()
            logging.info("removed virtual battery %s", key)
        sys.exit(0)

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    logging.info("starting: interval=%ds direct HID++ polling", args.interval)

    while True:
        try:
            devices = scan()
        except Exception as exc:
            logging.warning("scan failed: %s", exc)
            devices = {}

        for key in list(batteries):
            if key not in devices:
                if not args.dry_run:
                    batteries[key].destroy()
                del batteries[key]
                logging.info("removed virtual battery %s", key)

        for serial, (name, percent, charging) in devices.items():
            if args.dry_run:
                logging.info("dry run: would report %s (%s): %d%% %s", name, serial, percent, "charging" if charging else "discharging")
                continue
            battery = batteries.get(serial)
            if battery is None:
                try:
                    battery = VirtualBattery(args.uhid_device, name, serial, percent, charging)
                    batteries[serial] = battery
                    logging.info("created virtual battery for %s", name)
                except OSError as exc:
                    logging.error("cannot create uhid device for %s: %s", name, exc)
                    continue
            try:
                battery.update(percent, charging)
                logging.info("%s: %d%% %s", name, percent, "charging" if charging else "discharging")
            except OSError as exc:
                logging.warning("update failed for %s: %s", name, exc)
                battery.destroy()
                del batteries[serial]

        time.sleep(args.interval)


if __name__ == "__main__":
    main()
