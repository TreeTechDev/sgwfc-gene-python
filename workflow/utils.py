from collections.abc import Iterable


def flatten(nested_list):
    """Flatten a nested list recursively."""
    for item in nested_list:
        if isinstance(item, Iterable) and not isinstance(item, (str, bytes)):
            yield from flatten(item)
        else:
            yield item