from scripts.n2m.api import fetch_blocks


class DummyChildren:
    def __init__(self, pages):
        self._pages = pages
        self.calls = 0

    def list(self, block_id, start_cursor=None, page_size=None):
        # emulate pagination: return successive pages
        idx = self.calls
        self.calls += 1
        if idx < len(self._pages):
            data = self._pages[idx]
            return data
        return {"results": [], "has_more": False}


class DummyClient:
    def __init__(self, pages):
        self.blocks = type("B", (), {"children": DummyChildren(pages)})()


def test_fetch_blocks_pagination():
    pages = [
        {"results": [{"id": "a"}], "next_cursor": "c1", "has_more": True},
        {"results": [{"id": "b"}], "next_cursor": None, "has_more": False},
    ]
    client = DummyClient(pages)
    blocks = fetch_blocks(client, "someid")
    assert [b["id"] for b in blocks] == ["a", "b"]
