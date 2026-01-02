from scripts.n2m.convert import block_to_markdown, convert_blocks_to_markdown


def test_paragraph_to_md():
    block = {"type": "paragraph", "paragraph": {"rich_text": [{"plain_text": "Hello world"}]}}
    assert block_to_markdown(block) == "Hello world\n\n"


def test_headings_to_md():
    h1 = {"type": "heading_1", "heading_1": {"rich_text": [{"plain_text": "Title"}]}}
    assert block_to_markdown(h1) == "# Title\n\n"


def test_code_block():
    b = {"type": "code", "code": {"language": "python", "rich_text": [{"plain_text": "print(1)"}]}}
    assert "print(1)" in block_to_markdown(b)


def test_list_item_no_children():
    b = {"type": "bulleted_list_item", "bulleted_list_item": {"rich_text": [{"plain_text": "item"}]}, "has_children": False}
    assert convert_blocks_to_markdown([b]) == "- item\n"
