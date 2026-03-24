from pydantic import BaseModel, Field, field_validator, EmailStr
from typing import Optional
import phonenumbers


class OtpRequestSchema(BaseModel):
    """Schema for OTP request."""

    phone: str = Field(..., min_length=10, max_length=15)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        """Validate Indian phone number format."""
        try:
            parsed = phonenumbers.parse(v, "IN")
            if not phonenumbers.is_valid_number(parsed):
                raise ValueError("Invalid phone number")
            return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)
        except phonenumbers.NumberParseException:
            raise ValueError("Invalid phone number format")

    class Config:
        examples = [{"phone": "+919876543210"}]


class OtpVerifySchema(BaseModel):
    """Schema for OTP verification."""

    phone: str = Field(..., min_length=10, max_length=15)
    otp: str = Field(..., min_length=6, max_length=6)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        """Validate Indian phone number format."""
        try:
            parsed = phonenumbers.parse(v, "IN")
            if not phonenumbers.is_valid_number(parsed):
                raise ValueError("Invalid phone number")
            return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)
        except phonenumbers.NumberParseException:
            raise ValueError("Invalid phone number format")

    @field_validator("otp")
    @classmethod
    def validate_otp(cls, v: str) -> str:
        """Validate OTP format."""
        if not v.isdigit():
            raise ValueError("OTP must contain only digits")
        return v

    class Config:
        examples = [{"phone": "+919876543210", "otp": "123456"}]


class UserResponseSchema(BaseModel):
    """Schema for user response."""

    id: str
    name: Optional[str] = None
    phone: str
    village_id: Optional[str] = None
    language_pref: str = "hi"
    avatar_url: Optional[str] = None

    class Config:
        from_attributes = True


class TokenResponseSchema(BaseModel):
    """Schema for token response."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponseSchema
    expires_in: int = 1800

    class Config:
        examples = [
            {
                "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
                "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
                "token_type": "bearer",
                "expires_in": 1800,
                "user": {
                    "id": "123e4567-e89b-12d3-a456-426614174000",
                    "name": "John Doe",
                    "phone": "+919876543210",
                    "village_id": "123e4567-e89b-12d3-a456-426614174001",
                    "language_pref": "hi",
                    "avatar_url": None,
                },
            }
        ]


class RefreshTokenSchema(BaseModel):
    """Schema for refresh token request."""

    refresh_token: str = Field(...)

    class Config:
        examples = [
            {"refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."}
        ]


class UserUpdateSchema(BaseModel):
    """Schema for user update."""

    name: Optional[str] = Field(None, max_length=255)
    language_pref: Optional[str] = Field(None, pattern="^(hi|en|mr|gu)$")

    class Config:
        examples = [{"name": "John Doe", "language_pref": "hi"}]
