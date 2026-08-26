"""
app/core/hostels.py — Single source of truth for the LPU hostel list.
Update BOYS_HOSTELS and GIRLS_HOSTELS after verifying official names.
"""

BOYS_HOSTELS: list[str] = ["BH-1","BH-2","BH-3","BH-4","BH-5","BH-6","BH-7"]
GIRLS_HOSTELS: list[str] = ["GH-1","GH-2","GH-3"]
ALL_HOSTELS: list[str] = BOYS_HOSTELS + GIRLS_HOSTELS
BOYS_HOSTELS_SET: set[str] = set(BOYS_HOSTELS)
GIRLS_HOSTELS_SET: set[str] = set(GIRLS_HOSTELS)
ALL_HOSTELS_SET: set[str] = set(ALL_HOSTELS)
VALID_SEATERS: set[int] = {2, 3, 4, 5}
GENDER_HOSTEL_MAP: dict[str, set[str]] = {"male": BOYS_HOSTELS_SET, "female": GIRLS_HOSTELS_SET}

def get_hostels_for_gender(gender: str) -> list[str]:
    if gender == "male": return BOYS_HOSTELS
    elif gender == "female": return GIRLS_HOSTELS
    return ALL_HOSTELS

def is_hostel_valid_for_gender(hostel: str, gender: str) -> bool:
    allowed = GENDER_HOSTEL_MAP.get(gender)
    return hostel in (allowed if allowed else ALL_HOSTELS_SET)

def is_valid_hostel(hostel: str) -> bool: return hostel in ALL_HOSTELS_SET
def is_valid_seater(seater: int) -> bool: return seater in VALID_SEATERS
