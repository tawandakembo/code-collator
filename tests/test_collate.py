import pytest
from unittest.mock import mock_open, patch
from code_collator import collate

def test_is_binary_file():
    with patch('builtins.open', mock_open(read_data=b'\x00\x01\x02')):
        assert collate.is_binary_file('test.bin') == True
    
    with patch('builtins.open', mock_open(read_data=b'hello world')):
        assert collate.is_binary_file('test.txt') == False

def test_read_gitignore():
    with patch('builtins.open', mock_open(read_data='*.pyc\n__pycache__\n')):
        patterns = collate.read_gitignore('.')
        assert patterns == ['*.pyc', '__pycache__']

def test_should_ignore():
    patterns = ['*.pyc', '__pycache__']
    assert collate.should_ignore('test.pyc', patterns) == True
    assert collate.should_ignore('test.py', patterns) == False
    assert collate.should_ignore('.git/config', patterns) == True

@pytest.fixture
def mock_file_system(tmp_path):
    d = tmp_path / "test_dir"
    d.mkdir()
    (d / "test.py").write_text("print('hello')")
    (d / "test.pyc").write_bytes(b'\x00\x01\x02')
    return d

def test_collate_codebase(mock_file_system, capsys):
    output_file = mock_file_system / "output.md"
    collate.collate_codebase(str(mock_file_system), str(output_file))
    
    with open(output_file, 'r') as f:
        content = f.read()
    
    assert "# Collated Codebase" in content
    assert "test.py" in content
    assert "print('hello')" in content
    assert "test.pyc" in content
    assert "This is a binary file" in content

def test_main(mock_file_system, capsys):
    with patch('sys.argv', ['collate', '-p', str(mock_file_system), '-o', 'output.md']):
        collate.main()
    
    captured = capsys.readouterr()
    assert "Starting code collation" in captured.out
    assert "Code collation completed" in captured.out