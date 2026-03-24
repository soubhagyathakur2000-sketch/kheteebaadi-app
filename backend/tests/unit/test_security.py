import pytest
from datetime import timedelta, datetime, timezone
from unittest.mock import AsyncMock, patch
import string

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_otp,
    hash_password,
    verify_password,
)
from app.core.config import settings


class TestTokenGeneration:
    """Test JWT token generation."""

    def test_create_access_token_valid(self):
        """Test access token creation produces valid JWT."""
        data = {"sub": "test_user_123"}
        token = create_access_token(data)

        assert isinstance(token, str)
        assert len(token.split(".")) == 3  # JWT has 3 parts separated by dots

    def test_create_access_token_with_custom_expiry(self):
        """Test access token with custom expiration."""
        data = {"sub": "test_user_123"}
        expires_delta = timedelta(hours=2)
        token = create_access_token(data, expires_delta=expires_delta)

        assert isinstance(token, str)
        decoded = decode_token(token)
        assert decoded.get("sub") == "test_user_123"

    def test_create_refresh_token_valid(self):
        """Test refresh token creation."""
        data = {"sub": "test_user_123"}
        token = create_refresh_token(data)

        assert isinstance(token, str)
        assert len(token.split(".")) == 3
        decoded = decode_token(token)
        assert decoded.get("type") == "refresh"

    def test_create_access_token_contains_subject(self):
        """Test access token contains subject claim."""
        user_id = "550e8400-e29b-41d4-a716-446655440000"
        token = create_access_token({"sub": user_id})
        decoded = decode_token(token)

        assert decoded.get("sub") == user_id

    def test_create_access_token_contains_expiry(self):
        """Test access token contains expiration."""
        token = create_access_token({"sub": "user_123"})
        decoded = decode_token(token)

        assert "exp" in decoded
        # Exp should be in the future
        assert decoded["exp"] > datetime.now(timezone.utc).timestamp()


class TestTokenVerification:
    """Test JWT token verification."""

    def test_decode_token_valid(self):
        """Test decoding valid token."""
        data = {"sub": "test_user_123", "custom": "claim"}
        token = create_access_token(data)
        decoded = decode_token(token)

        assert decoded.get("sub") == "test_user_123"
        assert decoded.get("custom") == "claim"

    def test_decode_token_expired(self):
        """Test decoding expired token."""
        data = {"sub": "test_user_123"}
        expired_token = create_access_token(
            data, expires_delta=timedelta(seconds=-1)
        )

        from fastapi import HTTPException
        with pytest.raises(HTTPException) as exc_info:
            decode_token(expired_token)
        assert exc_info.value.status_code == 401

    def test_decode_token_invalid_signature(self):
        """Test decoding token with invalid signature."""
        token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyIiwiaWF0IjoxNjI1MDAwMDAwLCJleHAiOjE2MjUwMDMwMDB9.invalid_signature"

        from fastapi import HTTPException
        with pytest.raises(HTTPException) as exc_info:
            decode_token(token)
        assert exc_info.value.status_code == 401

    def test_decode_token_invalid_format(self):
        """Test decoding malformed token."""
        from fastapi import HTTPException
        with pytest.raises(HTTPException) as exc_info:
            decode_token("not.a.valid.token.format")
        assert exc_info.value.status_code == 401

    def test_decode_token_no_subject(self):
        """Test token without subject claim is accepted but has no sub."""
        data = {"custom": "claim"}
        token = create_access_token(data)
        decoded = decode_token(token)

        # Token decodes but sub is not present
        assert "custom" in decoded


class TestOtpGeneration:
    """Test OTP generation."""

    def test_generate_otp_six_digits(self):
        """Test OTP is 6 digits."""
        otp = generate_otp()

        assert len(otp) == 6
        assert otp.isdigit()

    def test_generate_otp_always_digits(self):
        """Test multiple OTP generations are digits."""
        for _ in range(10):
            otp = generate_otp()
            assert len(otp) == 6
            assert all(c in string.digits for c in otp)

    def test_generate_otp_uniqueness(self):
        """Test OTP generation produces different values."""
        otps = [generate_otp() for _ in range(100)]
        unique_otps = set(otps)

        # Allow for some collision but most should be unique
        assert len(unique_otps) > 90

    def test_generate_otp_respects_settings(self):
        """Test OTP length respects configuration."""
        otp = generate_otp()
        assert len(otp) == settings.OTP_LENGTH


class TestPasswordHashing:
    """Test password hashing and verification."""

    def test_hash_password_valid(self):
        """Test password hashing produces hash."""
        password = "secure_password_123"
        hashed = hash_password(password)

        assert isinstance(hashed, str)
        assert len(hashed) > len(password)
        assert hashed != password

    def test_verify_password_correct(self):
        """Test verifying correct password."""
        password = "secure_password_123"
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True

    def test_verify_password_incorrect(self):
        """Test verifying incorrect password."""
        password = "secure_password_123"
        wrong_password = "wrong_password_456"
        hashed = hash_password(password)

        assert verify_password(wrong_password, hashed) is False

    def test_hash_password_produces_different_hashes(self):
        """Test same password produces different hashes (salt variation)."""
        password = "secure_password_123"
        hash1 = hash_password(password)
        hash2 = hash_password(password)

        assert hash1 != hash2
        assert verify_password(password, hash1) is True
        assert verify_password(password, hash2) is True

    def test_hash_password_empty_string(self):
        """Test hashing empty password."""
        hashed = hash_password("")
        assert isinstance(hashed, str)
        assert verify_password("", hashed) is True

    def test_hash_password_special_characters(self):
        """Test hashing password with special characters."""
        password = "p@ssw0rd!#$%^&*()"
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True
        assert verify_password("p@ssw0rd!#$%^&*()", hashed) is True

    def test_hash_password_unicode(self):
        """Test hashing password with unicode characters."""
        password = "पासवर्ड123"
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True


class TestTokenWithCustomClaims:
    """Test token generation with custom claims."""

    def test_access_token_preserves_custom_claims(self):
        """Test custom claims are preserved in token."""
        data = {"sub": "user_123", "role": "farmer", "village_id": "village_456"}
        token = create_access_token(data)
        decoded = decode_token(token)

        assert decoded.get("sub") == "user_123"
        assert decoded.get("role") == "farmer"
        assert decoded.get("village_id") == "village_456"

    def test_refresh_token_includes_type_claim(self):
        """Test refresh token includes type claim."""
        data = {"sub": "user_123"}
        token = create_refresh_token(data)
        decoded = decode_token(token)

        assert decoded.get("type") == "refresh"
        assert decoded.get("sub") == "user_123"
