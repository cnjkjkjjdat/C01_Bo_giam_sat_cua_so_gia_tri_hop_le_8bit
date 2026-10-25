def model(sample, lower, upper):
    if lower > upper:
        return 0, 0, 0, 1

    below = int(sample < lower)
    above = int(sample > upper)
    inside = int(not below and not above)

    return below, inside, above, 0


def run():
    directed = [
        (49, 50, 100, (1,0,0,0)),
        (50, 50, 100, (0,1,0,0)),
        (51, 50, 100, (0,1,0,0)),
        (99, 50, 100, (0,1,0,0)),
        (100,50, 100, (0,1,0,0)),
        (101,50, 100, (0,0,1,0)),
        (75, 100, 50, (0,0,0,1)),
    ]

    for s, lo, hi, expected in directed:
        assert model(s, lo, hi) == expected

    # Representative valid-window exhaustive sample sweeps.
    for lo in range(0, 256, 17):
        for hi in range(lo, 256, 19):
            for s in range(256):
                b, i, a, e = model(s, lo, hi)
                assert e == 0
                assert b + i + a == 1
                assert not (b and i)
                assert not (i and a)
                assert not (b and a)

    # Representative invalid configurations.
    for lo in range(1, 256, 13):
        for hi in range(0, lo, 11):
            for s in range(0, 256, 7):
                assert model(s, lo, hi) == (0,0,0,1)

    print("C01 independent Python reference: PASS")


if __name__ == "__main__":
    run()
