import os
from pathlib import Path
import pytest

REPO_ROOT = Path("/Users/nicholasdudek/Desktop/Genie/GoldGate")
RETRIEVAL_FILE = REPO_ROOT / "Sources/GoldGate/Engine/GenieBrowserDOMRetrievalManager.swift"
CRAWLER_FILE = REPO_ROOT / "Sources/GoldGate/Engine/GenieFastWebCrawler.swift"
CARD_FILE = REPO_ROOT / "Sources/GoldGate/Views/AIEmotionPlayerWindowView.swift"
LOCAL_MODEL_FILE = REPO_ROOT / "Sources/GoldGate/Engine/LocalModelManager.swift"

INDEX_CRAWLER_FILE = REPO_ROOT / "Sources/GoldGate/Engine/GenieSearchIndexCrawlerEngine.swift"

def test_browser_dom_retrieval_manager_exists():
    assert RETRIEVAL_FILE.exists(), f"Missing {RETRIEVAL_FILE}"
    content = RETRIEVAL_FILE.read_text(encoding="utf-8")
    assert "class GenieBrowserDOMRetrievalManager" in content
    assert "struct GenieRetrievedWebItem" in content
    assert "fetchWikipediaSummary" in content
    assert "prefetchImage" in content
    assert "retrieveURL" in content
    assert "retrieveSearch" in content
    assert "GenieSearchIndexCrawlerEngine.shared.search" in content

def test_search_index_crawler_engine():
    assert INDEX_CRAWLER_FILE.exists(), f"Missing {INDEX_CRAWLER_FILE}"
    content = INDEX_CRAWLER_FILE.read_text(encoding="utf-8")
    assert "class GenieSearchIndexCrawlerEngine" in content
    assert "struct GenieSearchIndexResult" in content
    assert "queryGoogleSyndicationIndex" in content
    assert "queryOpenSearchIndex" in content
    assert "enrichResultsWithDeepCrawler" in content
    assert "parseGoogleNewsRSS" in content

def test_fast_web_crawler_dom_and_image_metadata():
    assert CRAWLER_FILE.exists(), f"Missing {CRAWLER_FILE}"
    content = CRAWLER_FILE.read_text(encoding="utf-8")
    assert "previewImageURL" in content
    assert "faviconURL" in content
    assert "domInteractiveCount" in content
    assert "extractMetaImage" in content
    assert "extractMetaDescription" in content
    assert "extractFavicon" in content
    assert "countDOMInteractiveElements" in content

def test_web_tool_card_view_background_retrieval_integration():
    assert CARD_FILE.exists(), f"Missing {CARD_FILE}"
    content = CARD_FILE.read_text(encoding="utf-8")
    assert "GenieBrowserDOMRetrievalManager.shared" in content
    assert "leadingMediaThumbnail" in content
    assert "Inspect DOM" in content
    assert "domElementsCount" in content
    assert "retrieval.retrieve(queryOrUrl: queryOrUrl)" in content

def test_local_model_manager_eager_retrieval_trigger():
    assert LOCAL_MODEL_FILE.exists(), f"Missing {LOCAL_MODEL_FILE}"
    content = LOCAL_MODEL_FILE.read_text(encoding="utf-8")
    assert "GenieBrowserDOMRetrievalManager.shared.retrieve" in content
    assert "GenieSearchIndexCrawlerEngine.shared.search" in content

