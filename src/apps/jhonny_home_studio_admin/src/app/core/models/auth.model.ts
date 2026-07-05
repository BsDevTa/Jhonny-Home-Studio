export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  fullName: string;
  email: string;
  password: string;
  confirmPassword: string;
}

export interface AuthUser {
  token: string;
  expiresAt: string;
  userId: string;
  fullName: string;
  email: string;
  role: string;
}
