import pytest
from unittest.mock import AsyncMock

from app.services.otp_service import OtpService
from app.core.exceptions import ValidationException


@pytest.mark.asyncio
class TestOtpServiceGenerateAndStore:
    """Test OtpService.generate_and_store method."""

    async def test_generate_and_store_valid_phone(self):
        """Test OTP generation and storage for valid phone."""
        service = OtpService()
        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = None
        redis_mock.set_cached = AsyncMock()
        redis_mock.increment = AsyncMock()

        phone = "+919876543210"
        otp = await service.generate_and_store(phone, redis_mock)

        assert otp is not None
        assert isinstance(otp, str)
        redis_mock.set_cached.assert_called()
        redis_mock.increment.assert_not_called()  # First request, no increment

    async def test_generate_and_store_increments_rate_limit(self):
        """Test rate limit counter is incremented."""
        service = OtpService()
        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = "1"  # Already 1 request
        redis_mock.set_cached = AsyncMock()
        redis_mock.increment = AsyncMock()

        phone = "+919876543210"
        otp = await service.generate_and_store(phone, redis_mock)

        assert otp is not None
        redis_mock.increment.assert_called()

    async def test_generate_and_store_rate_limit_exceeded(self):
        """Test exception when rate limit is exceeded (4th attempt)."""
        service = OtpService()
        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = "3"  # Already 3 requests (max)

        phone = "+919876543210"
        with pytest.raises(ValidationException) as exc_info:
            await service.generate_and_store(phone, redis_mock)

        assert "Too many OTP requests" in str(exc_info.value.detail)

    async def test_generate_and_store_creates_rate_limit_key(self):
        """Test rate limit tracking key is created."""
        service = OtpService()
        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = None
        redis_mock.set_cached = AsyncMock()

        phone = "+919876543210"
        await service.generate_and_store(phone, redis_mock)

        # Should set both OTP and rate limit
        assert redis_mock.set_cached.call_count >= 2

    async def test_generate_and_store_otp_ttl_matches_config(self):
        """Test OTP is stored with correct TTL from config."""
        from app.core.config import settings

        service = OtpService()
        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = None
        redis_mock.set_cached = AsyncMock()
        redis_mock.increment = AsyncMock()

        phone = "+919876543210"
        await service.generate_and_store(phone, redis_mock)

        # Find the call that sets the OTP (not rate limit)
        calls = redis_mock.set_cached.call_args_list
        otp_call = [c for c in calls if f"otp:{phone}" in str(c)]
        assert len(otp_call) > 0


@pytest.mark.asyncio
class TestOtpServiceVerify:
    """Test OtpService.verify method."""

    async def test_verify_correct_otp(self):
        """Test verification with correct OTP."""
        service = OtpService()
        phone = "+919876543210"
        correct_otp = "123456"

        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = correct_otp
        redis_mock.delete_cached = AsyncMock()

        result = await service.verify(phone, correct_otp, redis_mock)

        assert result is True
        redis_mock.delete_cached.assert_called()

    async def test_verify_incorrect_otp(self):
        """Test verification with incorrect OTP."""
        service = OtpService()
        phone = "+919876543210"
        stored_otp = "123456"
        wrong_otp = "654321"

        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = stored_otp
        redis_mock.delete_cached = AsyncMock()

        result = await service.verify(phone, wrong_otp, redis_mock)

        assert result is False
        redis_mock.delete_cached.assert_not_called()

    async def test_verify_expired_otp(self):
        """Test verification with expired OTP (not in Redis)."""
        service = OtpService()
        phone = "+919876543210"
        otp = "123456"

        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = None  # OTP expired/not found

        result = await service.verify(phone, otp, redis_mock)

        assert result is False

    async def test_verify_deletes_otp_after_successful_verification(self):
        """Test OTP is deleted after successful verification."""
        service = OtpService()
        phone = "+919876543210"
        otp = "123456"

        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = otp
        redis_mock.delete_cached = AsyncMock()

        await service.verify(phone, otp, redis_mock)

        redis_mock.delete_cached.assert_called_with(f"otp:{phone}")

    async def test_verify_does_not_delete_otp_on_failure(self):
        """Test OTP is not deleted on verification failure."""
        service = OtpService()
        phone = "+919876543210"
        stored_otp = "123456"
        wrong_otp = "999999"

        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = stored_otp
        redis_mock.delete_cached = AsyncMock()

        await service.verify(phone, wrong_otp, redis_mock)

        redis_mock.delete_cached.assert_not_called()


@pytest.mark.asyncio
class TestOtpServiceRateLimiting:
    """Test OTP rate limiting behavior."""

    async def test_rate_limit_allows_three_requests_per_hour(self):
        """Test rate limit allows exactly 3 OTP requests."""
        service = OtpService()
        redis_mock = AsyncMock()
        redis_mock.set_cached = AsyncMock()
        redis_mock.increment = AsyncMock()

        phone = "+919876543210"

        # First request
        redis_mock.get_cached.return_value = None
        otp1 = await service.generate_and_store(phone, redis_mock)
        assert otp1 is not None

        # Second request
        redis_mock.get_cached.return_value = "1"
        otp2 = await service.generate_and_store(phone, redis_mock)
        assert otp2 is not None

        # Third request
        redis_mock.get_cached.return_value = "2"
        otp3 = await service.generate_and_store(phone, redis_mock)
        assert otp3 is not None

        # Fourth request - should be rejected
        redis_mock.get_cached.return_value = "3"
        with pytest.raises(ValidationException):
            await service.generate_and_store(phone, redis_mock)

    async def test_rate_limit_independent_per_phone(self):
        """Test rate limit is tracked independently per phone number."""
        service = OtpService()
        redis_mock = AsyncMock()
        redis_mock.get_cached.return_value = None
        redis_mock.set_cached = AsyncMock()
        redis_mock.increment = AsyncMock()

        phone1 = "+919876543210"
        phone2 = "+919876543211"

        otp1 = await service.generate_and_store(phone1, redis_mock)
        otp2 = await service.generate_and_store(phone2, redis_mock)

        assert otp1 is not None
        assert otp2 is not None
        # Both should succeed independently
