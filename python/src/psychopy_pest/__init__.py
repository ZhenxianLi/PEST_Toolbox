"""PEST adaptive staircase (Taylor & Creelman, 1967) for PsychoPy.

:class:`PEST` is the dependency-free algorithm. :class:`PestHandler` wraps it
as a PsychoPy trial handler and needs PsychoPy; once the plugin is loaded it
is also available as ``psychopy.data.PestHandler``.
"""

from .pest import PEST

__version__ = "2.1.0"
__all__ = ["PEST", "PestHandler"]


def __getattr__(name):
    # Import the handler lazily so that PEST works without PsychoPy.
    if name == "PestHandler":
        from .handler import PestHandler
        return PestHandler
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
