"""Entry point for the Hello World application."""


def greet() -> str:
    return "Hello, World!"


def add(a: int, b: int) -> int:
    return a + b


def main() -> None:
    print(greet())


if __name__ == "__main__":
    main()
