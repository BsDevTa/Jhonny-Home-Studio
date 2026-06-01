export interface BusinessHourModel {
  id: string;
  dayOfWeek: number;
  dayName: string;
  isOpen: boolean;
  startTime: string;
  endTime: string;
  slotIntervalMinutes: number;
}

export interface UpdateBusinessHourRequest {
  dayOfWeek: number;
  isOpen: boolean;
  startTime: string;
  endTime: string;
  slotIntervalMinutes: number;
}

export interface BlockedDateModel {
  id: string;
  date: string;
  reason: string;
  isFullDay: boolean;
  startTime: string | null;
  endTime: string | null;
  createdAt: string;
  updatedAt: string | null;
}

export interface UpsertBlockedDateRequest {
  date: string;
  reason: string;
  isFullDay: boolean;
  startTime: string | null;
  endTime: string | null;
}
