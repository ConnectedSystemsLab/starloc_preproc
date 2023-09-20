
from argparse import ArgumentParser


def main():
    print("hi")
    parser = ArgumentParser()
    parser.add_argument("sample_rate", help="sample rate")
    parser.add_argument("center_freq", help="the center frequency of the channel")
    parser.add_argument("duration", help="the time period for one capture (s)")
    args = parser.parse_args()
    print(args.sample_rate, args.center_freq, args.duration)
if __name__ == '__main__':
    main()