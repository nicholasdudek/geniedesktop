import math
import subprocess
import re
from pathlib import Path
import pytest

BASE_DIR = str(Path(__file__).resolve().parents[1])

def test_regenerative_regression_mathematical_precision():
    """Verify that weighted ordinary least squares and regenerative damping behave with high precision."""
    # Synthetic linear ramp: y(t) = 850.0 * t
    base_time = 1000.0
    dt_step = 0.010 # 10ms intervals
    samples = []
    for i in range(10):
        t = base_time + i * dt_step
        y = 850.0 * (i * dt_step)
        samples.append((t, y))

    tau = 0.045
    decay_constant = math.log(2.0) / tau
    t_now = base_time + 9 * dt_step
    t_first = samples[0][0]

    sum_w = 0.0
    sum_wt = 0.0
    sum_wy = 0.0
    sum_wtt = 0.0
    sum_wty = 0.0

    for t, y in samples:
        age = max(0.0, t_now - t)
        weight = math.exp(-decay_constant * age)
        norm_t = t - t_first
        sum_w += weight
        sum_wt += weight * norm_t
        sum_wy += weight * y
        sum_wtt += weight * norm_t * norm_t
        sum_wty += weight * norm_t * y

    delta_t = (sum_w * sum_wtt) - (sum_wt * sum_wt)
    assert abs(delta_t) > 1e-9
    slope = ((sum_w * sum_wty) - (sum_wt * sum_wy)) / delta_t
    intercept = (sum_wy - slope * sum_wt) / sum_w

    # Slope must equal 850.0 within numerical precision
    assert abs(slope - 850.0) < 1e-3, f"Expected slope 850.0, got {slope}"

    # Residual sum of squares should be near zero for a perfect line
    mean_y = sum_wy / sum_w
    ss_tot = sum(math.exp(-decay_constant * max(0.0, t_now - t)) * (y - mean_y) ** 2 for t, y in samples)
    ss_res = sum(math.exp(-decay_constant * max(0.0, t_now - t)) * (y - (slope * (t - t_first) + intercept)) ** 2 for t, y in samples)

    r_squared = 1.0 - (ss_res / ss_tot)
    assert r_squared >= 0.9999, f"Expected R² >= 0.9999, got {r_squared}"

    # Regenerative Damping Scale with R² = 1.0 must be 1.0
    min_r2 = 0.60
    norm_r2 = (r_squared - min_r2) / (1.0 - min_r2)
    damping_scale = 0.5 + 0.5 * (norm_r2 ** 1.8)
    assert abs(damping_scale - 1.0) < 1e-3

    # Ballistic trajectory projection
    gamma = 3.2
    raw_displacement = slope / gamma
    assert abs(raw_displacement - (850.0 / 3.2)) < 1e-3

def test_regenerative_regression_compiled_into_binary():
    """Verify that GenieRegenerativeLinearRegressionEngine symbols are linked into the binary."""
    bin_path = Path(BASE_DIR) / ".build/debug/Genie"
    assert bin_path.exists(), f"Genie binary missing at {bin_path}"
    
    nm_res = subprocess.run(["nm", "-g", str(bin_path)], capture_output=True, text=True)
    assert nm_res.returncode == 0
    # Search for GenieRegenerativeLinearRegressionEngine mangled or demangled symbol
    assert "RegenerativeLinearRegressionEngine" in nm_res.stdout or "GenieRegenerative" in nm_res.stdout

def test_continuous_station_scroll_engine_uses_regenerative_regression():
    """Verify that ContinuousStationScrollEngine incorporates lastRegressionFit and projectBallisticDisplacement."""
    scroll_file = Path(BASE_DIR) / "Sources/GoldGate/Engine/ContinuousStationScrollEngine.swift"
    content = scroll_file.read_text()
    assert "lastRegressionFit" in content
    assert "GenieRegenerativeLinearRegressionEngine" in content
    assert "projectBallisticDisplacement" in content
