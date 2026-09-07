import pytest

def test_14_inch_macbook_pro_hardware_specifications():
    """Verify the physical hardware specs of the 14-inch Liquid Retina XDR display."""
    panel_width_px = 3024
    panel_height_px = 1964
    notch_height_px = 74
    
    # Safe 16:10 active display area below the notch
    safe_height_px = panel_height_px - notch_height_px
    assert safe_height_px == 1890
    
    # 16:10 aspect ratio verification
    aspect_ratio = panel_width_px / safe_height_px
    assert aspect_ratio == 1.6  # Exact 16:10 ratio (16 / 10 = 1.6)

def test_3x3_grid_max_resolution_safe_pixels_split():
    """
    Test whether the 14\" MacBook Pro's max physical resolution (safe 16:10 area 3024x1890)
    can split evenly into a 3x3 grid without any subpixel fractions.
    """
    width_px = 3024
    height_px = 1890
    
    sector_w = width_px / 3
    sector_h = height_px / 3
    
    # Assert exact whole numbers
    assert sector_w.is_integer()
    assert sector_h.is_integer()
    
    assert int(sector_w) == 1008
    assert int(sector_h) == 630
    
    # Assert zero remainders
    assert width_px % 3 == 0
    assert height_px % 3 == 0
    
    # Reconstruct total canvas
    assert int(sector_w) * 3 == width_px
    assert int(sector_h) * 3 == height_px

def test_3x3_grid_default_retina_points_split():
    """
    Test whether the 14\" MacBook Pro's default Retina scaled resolution (1512x945 points)
    can split evenly into a 3x3 grid without any subpixel fractions.
    """
    points_w = 1512
    points_h = 945  # 982pt full - 37pt notch
    
    sector_w = points_w / 3
    sector_h = points_h / 3
    
    assert sector_w.is_integer()
    assert sector_h.is_integer()
    
    assert int(sector_w) == 504
    assert int(sector_h) == 315
    
    assert points_w % 3 == 0
    assert points_h % 3 == 0
    
    # Check 2.0x retina relationship with physical pixels
    assert int(sector_w) * 2 == 1008
    assert int(sector_h) * 2 == 630

def test_9x9_universe_continuous_canvas_split():
    """
    Test whether the 9x9 continuous universe (81 screens) divides cleanly into
    both physical pixels and Retina points.
    """
    # Physical pixels
    width_px = 3024
    height_px = 1890
    assert width_px % 9 == 0
    assert height_px % 9 == 0
    assert width_px // 9 == 336
    assert height_px // 9 == 210
    
    # Retina points
    points_w = 1512
    points_h = 945
    assert points_w % 9 == 0
    assert points_h % 9 == 0
    assert points_w // 9 == 168
    assert points_h // 9 == 105

def test_full_panel_with_notch_split():
    """
    When using the full 3024x1964 panel (spanning behind the notch),
    the width divides evenly (1008px) and height divides into [655, 654, 655] px.
    """
    full_h_px = 1964
    assert full_h_px % 3 == 2  # 2 pixels remainder across 3 rows
    
    row_top = 655     # Top row with notch
    row_mid = 654     # Center row
    row_bot = 655     # Bottom row
    assert row_top + row_mid + row_bot == full_h_px
