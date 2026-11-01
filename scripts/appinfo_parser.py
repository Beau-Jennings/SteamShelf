from pathlib import Path
import struct


APPINFO_MAGIC_V41 = 0x07564429


def read_string_table(data, offset):
    string_count = struct.unpack_from("<I", data, offset)[0]
    position = offset + 4
    strings = []

    for _ in range(string_count):
        end = data.index(b"\x00", position)

        value = data[position:end].decode(
            "utf-8",
            errors="replace"
        )

        strings.append(value)
        position = end + 1

    return strings


def read_cstring(data, position):
    end = data.index(b"\x00", position)

    value = data[position:end].decode(
        "utf-8",
        errors="replace"
    )

    return value, end + 1


def parse_object(data, position, strings):
    result = {}

    while True:
        value_type = data[position]
        position += 1

        if value_type == 0x08:
            return result, position

        key_index = struct.unpack_from("<I", data, position)[0]
        position += 4

        key = strings[key_index]

        if value_type == 0x00:
            value, position = parse_object(
                data,
                position,
                strings
            )

        elif value_type == 0x01:
            value, position = read_cstring(
                data,
                position
            )

        elif value_type == 0x02:
            value = struct.unpack_from(
                "<I",
                data,
                position
            )[0]
            position += 4

        elif value_type == 0x03:
            value = struct.unpack_from(
                "<f",
                data,
                position
            )[0]
            position += 4

        elif value_type == 0x04:
            value = struct.unpack_from(
                "<I",
                data,
                position
            )[0]
            position += 4

        elif value_type == 0x05:
            end = data.index(b"\x00\x00", position)

            if (end - position) % 2 != 0:
                end += 1

            value = data[position:end].decode(
                "utf-16-le",
                errors="replace"
            )
            position = end + 2

        elif value_type == 0x06:
            value = data[position:position + 4]
            position += 4

        elif value_type == 0x07:
            value = struct.unpack_from(
                "<Q",
                data,
                position
            )[0]
            position += 8

        elif value_type == 0x0A:
            value = struct.unpack_from(
                "<q",
                data,
                position
            )[0]
            position += 8

        else:
            raise RuntimeError(
                f"Unknown KeyValues type {hex(value_type)} "
                f"at byte {position - 5}"
            )

        result[key] = value


class AppInfoParser:
    def __init__(self, appinfo_file):
        self.appinfo_file = Path(appinfo_file)

        with self.appinfo_file.open("rb") as file:
            self.data = file.read()

        magic = struct.unpack_from("<I", self.data, 0)[0]

        if magic != APPINFO_MAGIC_V41:
            raise RuntimeError(
                f"Unsupported appinfo.vdf format: {hex(magic)}"
            )

        self.string_table_offset = struct.unpack_from(
            "<Q",
            self.data,
            8
        )[0]

        self.strings = read_string_table(
            self.data,
            self.string_table_offset
        )

    def get_app(self, target_appid):
        app_position = 16

        while app_position < self.string_table_offset:
            appid, record_size = struct.unpack_from(
                "<II",
                self.data,
                app_position
            )

            if appid == 0:
                break

            if appid == target_appid:
                payload_position = app_position + 68

                app_data, _ = parse_object(
                    self.data,
                    payload_position,
                    self.strings
                )

                return app_data["appinfo"]

            app_position += 8 + record_size

        return None
