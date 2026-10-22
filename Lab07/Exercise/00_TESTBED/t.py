import math

DRAM_FILE = "DRAM_init.dat"

# --------------------------------------------------
# Address map assumption from your figure:
# BANK0: 0x0000 ~ 0x3FFF
# BANK1: 0x4000 ~ 0x7FFF
# BANK2: 0x8000 ~ 0xBFFF
# BANK3: 0xC000 ~ 0xFFFF
#
# Each row spans 0x100 addresses inside one bank.
# So row r uses offsets:
#   r*0x100 ~ r*0x100 + 0xFF
# Total rows per bank = 64
# --------------------------------------------------

BANK_BASES = [0x0000, 0x4000, 0x8000, 0xC000]
ROW_SIZE = 0x100
NUM_ROWS = 64
WORDS_PER_ROW_PER_BANK = 256
EPS = 1e-9


def load_dram(filename):
    dram = {}
    with open(filename, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) != 2:
                continue

            addr_str, data_str = parts
            if not addr_str.startswith("@"):
                continue

            addr = int(addr_str[1:], 16)
            data = int(data_str, 16)
            dram[addr] = data
    return dram


def to_signed_64(x):
    """Convert unsigned 64-bit integer to signed 64-bit integer."""
    if x & (1 << 63):
        return x - (1 << 64)
    return x


def get_row_words(dram, row_idx, signed=False):
    """
    Read the same row across 4 banks.
    Each row contributes 256 words from each bank => total 1024 words.
    """
    words = []
    row_offset = row_idx * ROW_SIZE

    for bank_base in BANK_BASES:
        start_addr = bank_base + row_offset
        for col in range(WORDS_PER_ROW_PER_BANK):
            addr = start_addr + col
            if addr not in dram:
                raise KeyError(f"Address @%04X not found in DRAM_init.dat" % addr)

            val = dram[addr]
            if signed:
                val = to_signed_64(val)
            words.append(val)

    return words


def calc_mu_sigma(words):
    n = len(words)
    if n == 0:
        return 0.0, 0.0, 0.0

    mu = sum(words) / n
    sigma2 = sum((w - mu) ** 2 for w in words) / n
    sigma = math.sqrt(sigma2)
    return mu, sigma2, sigma


def filter_range_mu_sigma(words, mu, sigma):
    """
    Standard interval filter:
        mu - sigma <= word <= mu + sigma
    """
    low = mu - sigma
    high = mu + sigma
    return [i for i, w in enumerate(words) if low <= w <= high]


def filter_range_sigma_mu(words, mu, sigma):
    """
    Literal version of what you wrote:
        sigma - mu <= word <= sigma + mu
    Usually not the standard form, but kept here in case you want it.
    """
    low = sigma - mu
    high = sigma + mu
    return [i for i, w in enumerate(words) if low <= w <= high]


def filter_squared(words, mu, sigma2):
    """
    Squared-distance form:
        (word - mu)^2 <= sigma^2
    """
    return [i for i, w in enumerate(words) if (w - mu) ** 2 <= sigma2 + EPS]


def compare_filters(dram, signed=False, use_literal_sigma_minus_mu=False):
    total_same = 0
    total_diff = 0

    for row_idx in range(NUM_ROWS):
        words = get_row_words(dram, row_idx, signed=signed)
        mu, sigma2, sigma = calc_mu_sigma(words)

        if use_literal_sigma_minus_mu:
            idx_range = filter_range_sigma_mu(words, mu, sigma)
            mode_name = "sigma-mu <= w <= sigma+mu"
        else:
            idx_range = filter_range_mu_sigma(words, mu, sigma)
            mode_name = "mu-sigma <= w <= mu+sigma"

        idx_sq = filter_squared(words, mu, sigma2)

        set_range = set(idx_range)
        set_sq = set(idx_sq)

        same = (set_range == set_sq)

        print("=" * 80)
        print(f"ROW {row_idx:02d}")
        print(f"N      = {len(words)}")
        print(f"mu     = {mu}")
        print(f"sigma2 = {sigma2}")
        print(f"sigma  = {sigma}")
        print(f"range mode: {mode_name}")
        print(f"range kept count   = {len(idx_range)}")
        print(f"square kept count  = {len(idx_sq)}")
        print(f"same result?       = {same}")

        if not same:
            only_range = sorted(set_range - set_sq)
            only_sq = sorted(set_sq - set_range)

            print(f"Only in range filter : {len(only_range)} items")
            if only_range:
                print("  first few indices:", only_range[:20])

            print(f"Only in square filter: {len(only_sq)} items")
            if only_sq:
                print("  first few indices:", only_sq[:20])

            total_diff += 1
        else:
            total_same += 1

    print("\n" + "#" * 80)
    print("SUMMARY")
    print(f"Same rows : {total_same}")
    print(f"Diff rows : {total_diff}")
    print("#" * 80)


if __name__ == "__main__":
    dram = load_dram(DRAM_FILE)

    print("=== Unsigned 64-bit mode, standard mu+/-sigma comparison ===")
    compare_filters(
        dram,
        signed=False,
        use_literal_sigma_minus_mu=False
    )

    # 如果你真的想測你原本字面上的 sigma-mu <= w <= sigma+mu，就把下面打開
    # print("\n=== Unsigned 64-bit mode, literal sigma±mu comparison ===")
    # compare_filters(
    #     dram,
    #     signed=False,
    #     use_literal_sigma_minus_mu=True
    # )

    # 如果你懷疑資料其實應該當 signed 64-bit，看這個
    # print("\n=== Signed 64-bit mode, standard mu±sigma comparison ===")
    # compare_filters(
    #     dram,
    #     signed=True,
    #     use_literal_sigma_minus_mu=False
    # )