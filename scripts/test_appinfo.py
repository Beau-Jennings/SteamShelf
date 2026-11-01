from pathlib import Path
import struct


APPINFO_MAGIC_V41 = 0x07564429
TARGET_APPID = 17390

appinfo_file = Path.home() / ".local/share/Steam/appcache/appinfo.vdf"


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

        # 0x08 marks the end of the current object.
        if value_type == 0x08:
            return result, position

        key_index = struct.unpack_from("<I", data, position)[0]
        position += 4

        key = strings[key_index]

        # Nested object
        if value_type == 0x00:
            value, position = parse_object(
                data,
                position,
                strings
            )

        # Null-terminated UTF-8 string
        elif value_type == 0x01:
            value, position = read_cstring(
                data,
                position
            )

        # 32-bit integer
        elif value_type == 0x02:
            value = struct.unpack_from(
                "<I",
                data,
                position
            )[0]

            position += 4

        # 32-bit float
        elif value_type == 0x03:
            value = struct.unpack_from(
                "<f",
                data,
                position
            )[0]

            position += 4

        # Pointer-sized value stored as 32 bits
        elif value_type == 0x04:
            value = struct.unpack_from(
                "<I",
                data,
                position
            )[0]

            position += 4

        # Wide string
        elif value_type == 0x05:
            end = data.index(b"\x00\x00", position)

            if (end - position) % 2 != 0:
                end += 1

            value = data[position:end].decode(
                "utf-16-le",
                errors="replace"
            )

            position = end + 2

        # Color stored as four bytes
        elif value_type == 0x06:
            value = data[position:position + 4]
            position += 4

        # Unsigned 64-bit integer
        elif value_type == 0x07:
            value = struct.unpack_from(
                "<Q",
                data,
                position
            )[0]

            position += 8

        # Signed 64-bit integer
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


with appinfo_file.open("rb") as file:
    data = file.read()


# ----- Read appinfo.vdf header -----

magic = struct.unpack_from("<I", data, 0)[0]

if magic != APPINFO_MAGIC_V41:
    raise RuntimeError(
        f"Unsupported appinfo.vdf format: {hex(magic)}"
    )

universe = struct.unpack_from("<I", data, 4)[0]
string_table_offset = struct.unpack_from("<Q", data, 8)[0]

strings = read_string_table(
    data,
    string_table_offset
)


# ----- Find the requested application -----

app_position = 16
target_position = None

while app_position < string_table_offset:
    appid, record_size = struct.unpack_from(
        "<II",
        data,
        app_position
    )

    if appid == 0:
        break

    if appid == TARGET_APPID:
        target_position = app_position
        break

    app_position += 8 + record_size


if target_position is None:
    raise RuntimeError(
        f"App {TARGET_APPID} was not found."
    )


# Skip:
# 8 bytes  -> App ID + record size
# 60 bytes -> fixed app metadata

payload_position = target_position + 68


# ----- Decode the application's KeyValues tree -----

app_data, _ = parse_object(
    data,
    payload_position,
    strings
)

appinfo = app_data["appinfo"]
common = appinfo["common"]

print(f"App ID: {appinfo['appid']}")
print(f"Name: {common['name']}")
print(f"Type: {common['type']}")
print(f"Common: {common}")
