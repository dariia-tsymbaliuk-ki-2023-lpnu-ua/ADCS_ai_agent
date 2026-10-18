from hello_world.main import add, greet, main


def test_greet():
    assert greet() == "Hello, World!"


def test_basic_addition():
    assert add(2, 3) == 5


def test_main_prints_greeting(capsys):
    main()
    assert capsys.readouterr().out.strip() == "Hello, World!"
