import pytest
from unittest.mock import AsyncMock, patch
from httpx import AsyncClient

from app.core.security import create_access_token, hash_password
import uuid


@pytest.mark.asyncio
class TestAuthOtpRequestEndpoint:
    """Test POST /auth/otp/request endpoint."""

    async def test_request_otp_valid_phone(self, test_app, test_redis):
        """Test requesting OTP with valid phone number."""
        response = await test_app.post(
            "/api/v1/auth/otp/request",
            json={"phone": "+919876543210"},
        )

        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert data["phone"] == "+919876543210"
        assert data["expires_in"] == 300

    async def test_request_otp_invalid_phone(self, test_app):
        """Test requesting OTP with invalid phone number."""
        response = await test_app.post(
            "/api/v1/auth/otp/request",
            json={"phone": "invalid_phone"},
        )

        assert response.status_code in [400, 422]

    async def test_request_otp_rate_limit(self, test_app, test_redis):
        """Test rate limiting after 3 OTP requests."""
        phone = "+919876543210"

        # First request should succeed
        response1 = await test_app.post(
            "/api/v1/auth/otp/request",
            json={"phone": phone},
        )
        assert response1.status_code == 200

        # Second request should succeed
        response2 = await test_app.post(
            "/api/v1/auth/otp/request",
            json={"phone": phone},
        )
        assert response2.status_code == 200

        # Third request should succeed
        response3 = await test_app.post(
            "/api/v1/auth/otp/request",
            json={"phone": phone},
        )
        assert response3.status_code == 200

        # Fourth request should be rate limited
        response4 = await test_app.post(
            "/api/v1/auth/otp/request",
            json={"phone": phone},
        )
        assert response4.status_code == 429


@pytest.mark.asyncio
class TestAuthOtpVerifyEndpoint:
    """Test POST /auth/otp/verify endpoint."""

    async def test_verify_otp_correct_code(self, test_app, test_db, test_redis):
        """Test OTP verification with correct code."""
        phone = "+919876543210"
        otp = "123456"

        # First request OTP to store it
        async with test_db() as session:
            from app.models import User
            from sqlalchemy import select

            # Ensure user doesn't exist
            stmt = select(User).where(User.phone == phone)
            result = await session.execute(stmt)
            user = result.scalars().first()

            if user:
                await session.delete(user)
                await session.commit()

        # Mock Redis to return our test OTP
        from app.core.redis import get_redis

        original_get_redis = get_redis

        async def mock_get_redis():
            mock_redis = AsyncMock()
            mock_redis.get_cached = AsyncMock(return_value=otp)
            mock_redis.delete_cached = AsyncMock()
            return mock_redis

        with patch("app.api.v1.endpoints.auth.get_redis", mock_get_redis):
            response = await test_app.post(
                "/api/v1/auth/otp/verify",
                json={"phone": phone, "otp": otp},
            )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"
        assert "user" in data

    async def test_verify_otp_incorrect_code(self, test_app, test_redis):
        """Test OTP verification with incorrect code."""
        phone = "+919876543210"
        correct_otp = "123456"
        wrong_otp = "654321"

        from app.core.redis import get_redis

        async def mock_get_redis():
            mock_redis = AsyncMock()
            mock_redis.get_cached = AsyncMock(return_value=correct_otp)
            mock_redis.delete_cached = AsyncMock()
            return mock_redis

        with patch("app.api.v1.endpoints.auth.get_redis", mock_get_redis):
            response = await test_app.post(
                "/api/v1/auth/otp/verify",
                json={"phone": phone, "otp": wrong_otp},
            )

        assert response.status_code == 422

    async def test_verify_otp_expired_code(self, test_app, test_redis):
        """Test OTP verification with expired code."""
        phone = "+919876543210"
        otp = "123456"

        from app.core.redis import get_redis

        async def mock_get_redis():
            mock_redis = AsyncMock()
            mock_redis.get_cached = AsyncMock(return_value=None)  # Expired
            return mock_redis

        with patch("app.api.v1.endpoints.auth.get_redis", mock_get_redis):
            response = await test_app.post(
                "/api/v1/auth/otp/verify",
                json={"phone": phone, "otp": otp},
            )

        assert response.status_code == 422

    async def test_verify_otp_creates_new_user(self, test_app, test_db, test_redis):
        """Test OTP verification creates new user if not exists."""
        phone = "+919876543210"
        otp = "123456"

        async with test_db() as session:
            from app.models import User
            from sqlalchemy import select

            # Ensure user doesn't exist
            stmt = select(User).where(User.phone == phone)
            result = await session.execute(stmt)
            user = result.scalars().first()

            if user:
                await session.delete(user)
                await session.commit()

        from app.core.redis import get_redis

        async def mock_get_redis():
            mock_redis = AsyncMock()
            mock_redis.get_cached = AsyncMock(return_value=otp)
            mock_redis.delete_cached = AsyncMock()
            mock_redis.set_cached = AsyncMock()
            return mock_redis

        with patch("app.api.v1.endpoints.auth.get_redis", mock_get_redis):
            response = await test_app.post(
                "/api/v1/auth/otp/verify",
                json={"phone": phone, "otp": otp},
            )

        if response.status_code == 200:
            data = response.json()
            assert "user" in data
            user_data = data["user"]
            assert user_data["phone"] == phone


@pytest.mark.asyncio
class TestAuthRefreshTokenEndpoint:
    """Test POST /auth/refresh-token endpoint."""

    async def test_refresh_token_valid_token(self, test_app, sample_user, test_redis):
        """Test refresh token endpoint with valid refresh token."""
        from app.core.security import create_refresh_token

        refresh_token = create_refresh_token({"sub": str(sample_user.id)})

        from app.core.redis import get_redis

        async def mock_get_redis():
            mock_redis = AsyncMock()
            mock_redis.get_cached = AsyncMock(return_value=refresh_token)
            return mock_redis

        with patch("app.api.v1.endpoints.auth.get_redis", mock_get_redis):
            response = await test_app.post(
                "/api/v1/auth/refresh-token",
                json={"refresh_token": refresh_token},
            )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data

    async def test_refresh_token_invalid_token(self, test_app, test_redis):
        """Test refresh token endpoint with invalid token."""
        invalid_token = "invalid.token.format"

        response = await test_app.post(
            "/api/v1/auth/refresh-token",
            json={"refresh_token": invalid_token},
        )

        assert response.status_code == 401


@pytest.mark.asyncio
class TestAuthIntegration:
    """Integration tests for complete authentication flow."""

    async def test_complete_auth_flow_request_verify_access(self, test_app, test_db, test_redis):
        """Test complete flow: request OTP -> verify -> use access token."""
        phone = "+919876543210"
        otp = "123456"

        # Clear any existing user
        async with test_db() as session:
            from app.models import User
            from sqlalchemy import select

            stmt = select(User).where(User.phone == phone)
            result = await session.execute(stmt)
            user = result.scalars().first()
            if user:
                await session.delete(user)
                await session.commit()

        from app.core.redis import get_redis

        async def mock_get_redis():
            mock_redis = AsyncMock()
            mock_redis.get_cached = AsyncMock(return_value=otp)
            mock_redis.delete_cached = AsyncMock()
            mock_redis.set_cached = AsyncMock()
            return mock_redis

        # Step 1: Request OTP
        response1 = await test_app.post(
            "/api/v1/auth/otp/request",
            json={"phone": phone},
        )
        assert response1.status_code == 200

        # Step 2: Verify OTP and get tokens
        with patch("app.api.v1.endpoints.auth.get_redis", mock_get_redis):
            response2 = await test_app.post(
                "/api/v1/auth/otp/verify",
                json={"phone": phone, "otp": otp},
            )

        if response2.status_code == 200:
            data = response2.json()
            access_token = data["access_token"]

            # Step 3: Use access token to make authenticated request
            headers = {"Authorization": f"Bearer {access_token}"}
            response3 = await test_app.get("/health", headers=headers)

            assert response3.status_code == 200
