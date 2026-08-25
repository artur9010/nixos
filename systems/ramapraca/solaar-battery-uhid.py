#!/usr/bin/env python3
"""Bridge battery readings from Solaar to virtual HID batteries via /dev/uhid.

Each Solaar device that reports a battery gets a virtual uhid device whose
report descriptor carries HID Battery System usages (page 0x85):
  - 0x44 Charging               (1 byte, 0 = discharging, 1 = charging)
  - 0x65 Absolute State of Charge (1 byte, 0-100)
The kernel turns these into a power_supply class device, which UPower and the
KDE Power and Battery applet pick up automatically.

Runs as root (needs /dev/uhid and the hidraw devices Solaar talks to).
"""

import argparse
import ctypes
import logging
import os
import re
import select
import signal
import subprocess
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

# The kernel (drivers/hid/hid-input.c) only wires up an HID battery when the
# device passes IS_INPUT_APPLICATION(): the top-level application collection
# must be a Consumer Control one.  The Play/Pause key bit is required because
# battery (EV_PWR) usages alone leave the input device "unpopulated", which
# makes hidinput_connect() unwind and stops all input report processing.
# Input report layout: [charging(1), percent(1), key bit + padding(1)].
REPORT_DESCRIPTOR = bytes(
    [
        0x05, 0x0C,          # Usage Page (Consumer)
        0x09, 0x01,          # Usage (Consumer Control)
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
        0x05, 0x0C,          #   Usage Page (Consumer)
        0x09, 0xCD,          #   Usage (Play/Pause)
        0x75, 0x01,          #   Report Size (1)
        0x95, 0x01,          #   Report Count (1)
        0x81, 0x02,          #   Input (Data, Var, Abs)
        0x95, 0x07,          #   Report Count (7)
        0x81, 0x03,          #   Input (Const, Var, Abs) padding
        0xC0,                # End Collection
    ]
)
REPORT_SIZE = 3


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


DEVICE_HEADER_RE = re.compile(r"^ {0,3}(\d+):\s*(.+?)\s*$")
SERIAL_RE = re.compile(r"^\s*Serial number:\s*(\S+)")
BATTERY_RE = re.compile(r"^\s*Battery:\s*(\d+)%,?\s*(\S+)")
STATUS_CHARGING = ("RECHARGING", "ALMOST_FULL", "SLOW_RECHARGE")


def parse_solaar_output(text):
    devices = {}
    name = None
    serial = None
    battery = None

    def commit():
        if serial and battery:
            devices[serial] = (name or serial, battery[0], battery[1])

    for line in text.splitlines():
        header = DEVICE_HEADER_RE.match(line)
        if header:
            commit()
            name = header.group(2)
            serial = None
            battery = None
            continue
        serial_match = SERIAL_RE.match(line)
        if serial_match:
            serial = serial_match.group(1)
            continue
        battery_match = BATTERY_RE.match(line)
        if battery_match:
            pct = int(battery_match.group(1))
            status = battery_match.group(2).rstrip(".").split(".")[-1].upper()
            charging = 1 if any(s in status for s in STATUS_CHARGING) else 0
            battery = (pct, charging)
    commit()
    return devices


def query_solaar(solaar_bin):
    proc = subprocess.run(
        [solaar_bin, "show"],
        capture_output=True,
        text=True,
        timeout=90,
    )
    return parse_solaar_output(proc.stdout)


class VirtualBattery:
    def __init__(self, uhid_path, name, uniq, percent, charging, vendor=0x046D, product=0xB034):
        self.name = name
        self.uniq = uniq
        self.report_state = bytearray(
            [1 if charging else 0, percent, 0]
        )
        self.fd = os.open(uhid_path, os.O_RDWR | os.O_NONBLOCK | os.O_CLOEXEC)
        event = UhidEvent()
        memset(event, 0)
        event.type = UHID_CREATE2
        create = event.u.create2
        create.name = bytes_field(name, 128)
        create.phys = bytes_field("solaar-battery-uhid", 64)
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
    parser.add_argument("--solaar-bin", default="solaar", help="path to the solaar CLI")
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

    logging.info("starting: interval=%ds solaar=%s", args.interval, args.solaar_bin)

    while True:
        try:
            devices = query_solaar(args.solaar_bin)
        except Exception as exc:
            logging.warning("solaar query failed: %s", exc)
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
