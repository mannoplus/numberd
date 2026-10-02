import os
import json
import unittest
from unittest.mock import patch, MagicMock
from py_backend.engine import GAME_PHYSICS, run_monte_carlo_simulation, calculate_metrics, generate_trio_strategy
from py_backend.openrouter import (
    call_openrouter_model,
    extract_json_from_response,
    validate_and_merge_predictions,
    generate_predictions_with_openrouter,
    sanitize_log_message,
    DEFAULT_MODEL_CHAIN
)
from py_backend.index import app

class TestOpenRouterSubsystem(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        self.mock_draws = [
            [3, 8, 15, 22, 29, 36],
            [1, 9, 14, 20, 28, 35],
            [5, 11, 18, 25, 31, 37],
            [2, 7, 16, 23, 30, 38],
            [4, 12, 19, 26, 33, 34]
        ]

    def test_sanitize_log_message(self):
        secret = "sk-or-v1-secret123456789"
        msg = f"Request failed with Authorization: Bearer {secret} and key {secret}"
        sanitized = sanitize_log_message(msg, secret)
        self.assertNotIn(secret, sanitized)
        self.assertIn("[REDACTED]", sanitized)

    def test_json_extractor(self):
        # Plain json
        raw = '{"alpha": {"numbers": [1, 2, 3]}}'
        self.assertEqual(extract_json_from_response(raw), {"alpha": {"numbers": [1, 2, 3]}})

        # Markdown wrapped
        markdown = '```json\n{"beta": {"numbers": [4, 5, 6]}}\n```'
        self.assertEqual(extract_json_from_response(markdown), {"beta": {"numbers": [4, 5, 6]}})

        # Text with markdown and leading text
        messy = 'Here is the prediction:\n```json\n{"gamma": {"numbers": [7, 8, 9]}}\n```\nHope you enjoy!'
        self.assertEqual(extract_json_from_response(messy), {"gamma": {"numbers": [7, 8, 9]}})

    def test_deterministic_fallback_when_no_key(self):
        with patch.dict(os.environ, {"OPENROUTER_API_KEY": ""}):
            result = generate_predictions_with_openrouter("super_lotto_638", self.mock_draws)
            self.assertEqual(result["modelUsed"], "deterministic_fallback")
            self.assertIn("alpha", result)
            self.assertIn("beta", result)
            self.assertIn("gamma", result)
            self.assertEqual(len(result["alpha"]["numbers"]), 6)
            self.assertEqual(len(result["beta"]["numbers"]), 6)
            self.assertEqual(len(result["gamma"]["numbers"]), 6)
            self.assertIsNotNone(result["alpha"]["special"])
            self.assertGreater(result["alpha"]["confidenceScore"], 0.7)

    @patch("requests.post")
    def test_exponential_backoff_and_retry(self, mock_post):
        # First 2 attempts return 429, 3rd returns 200
        mock_resp_429 = MagicMock()
        mock_resp_429.status_code = 429

        mock_resp_200 = MagicMock()
        mock_resp_200.status_code = 200
        mock_resp_200.json.return_value = {
            "choices": [{"message": {"content": '{"summary": "test"}'}}]
        }

        mock_post.side_effect = [mock_resp_429, mock_resp_429, mock_resp_200]

        with patch("time.sleep") as mock_sleep:
            res = call_openrouter_model("openrouter/free", [{"role": "user", "content": "hi"}], max_retries=3)
            self.assertEqual(res, '{"summary": "test"}')
            self.assertEqual(mock_sleep.call_count, 2)
            # Verify exponential backoff delays (1.0s, 2.0s)
            mock_sleep.assert_any_call(1.0)
            mock_sleep.assert_any_call(2.0)

    @patch("py_backend.openrouter.call_openrouter_model")
    def test_model_fallback_chain(self, mock_call):
        # 1st model (openrouter/free) fails
        # 2nd model (qwen/qwen-2.5-72b-instruct:free) succeeds
        valid_response = json.dumps({
            "summary": "AI generated prediction",
            "alpha": {
                "numbers": [1, 5, 10, 15, 20, 25],
                "special": 3,
                "confidenceScore": 0.91,
                "justification": "AI balanced",
                "riskProfile": "Low Variance",
                "narrative": "Detailed narrative"
            },
            "beta": {
                "numbers": [8, 9, 14, 20, 28, 35],
                "special": 5,
                "confidenceScore": 0.77,
                "justification": "AI momentum",
                "riskProfile": "High Momentum",
                "narrative": "Detailed narrative"
            },
            "gamma": {
                "numbers": [6, 13, 21, 27, 32, 38],
                "special": 7,
                "confidenceScore": 0.55,
                "justification": "AI chaos",
                "riskProfile": "Extreme",
                "narrative": "Detailed narrative"
            }
        })

        mock_call.side_effect = [None, valid_response]

        with patch.dict(os.environ, {"OPENROUTER_API_KEY": "test_key"}):
            result = generate_predictions_with_openrouter("super_lotto_638", self.mock_draws)
            self.assertEqual(result["modelUsed"], "qwen/qwen-2.5-72b-instruct:free")
            self.assertEqual(result["alpha"]["numbers"], [1, 5, 10, 15, 20, 25])
            self.assertEqual(result["alpha"]["confidenceScore"], 0.91)
            self.assertEqual(result["alpha"]["special"], 3)
            self.assertEqual(mock_call.call_count, 2)

    def test_flask_endpoints(self):
        # Health check
        res_health = self.app.get("/api/health")
        self.assertEqual(res_health.status_code, 200)
        data = res_health.get_json()
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["aiProvider"], "OpenRouter")
        self.assertIn("openrouter/free", data["models"])

        with patch.dict(os.environ, {"OPENROUTER_API_KEY": ""}):
            # Predict all strategies
            res_predict = self.app.post("/api/predict", json={
                "gameId": "daily_cash_539",
                "draws": [[1, 2, 3, 4, 5], [10, 11, 12, 13, 14]]
            })
            self.assertEqual(res_predict.status_code, 200)
            p_data = res_predict.get_json()
            self.assertTrue(p_data["success"])
            self.assertEqual(p_data["gameId"], "daily_cash_539")
            self.assertIn("alpha", p_data)
            self.assertIn("beta", p_data)
            self.assertIn("gamma", p_data)
            self.assertEqual(len(p_data["alpha"]["numbers"]), 5)

            # Single strategy routing
            res_single = self.app.post("/api/predict", json={
                "gameId": "super_lotto_638",
                "strategy": "alpha",
                "draws": self.mock_draws
            })
            self.assertEqual(res_single.status_code, 200)
            s_data = res_single.get_json()
            self.assertTrue(s_data["success"])
            self.assertEqual(s_data["strategy"], "alpha")
            self.assertIn("prediction", s_data)
            self.assertEqual(len(s_data["prediction"]["numbers"]), 6)

        # Monte Carlo simulation endpoint
        res_mc = self.app.post("/api/predict/monte-carlo", json={
            "gameId": "lotto_649",
            "draws": self.mock_draws
        })
        self.assertEqual(res_mc.status_code, 200)
        mc_data = res_mc.get_json()
        self.assertTrue(mc_data["success"])
        self.assertEqual(len(mc_data["optimalNumbers"]), 6)
        self.assertEqual(mc_data["iterations"], 15000)

if __name__ == "__main__":
    unittest.main()
