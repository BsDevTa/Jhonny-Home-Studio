import { AppointmentListModel } from './appointment.model';

export interface CustomerListModel {
  customerId: string;
  userId: string;
  fullName: string;
  email: string;
  phone?: string | null;
  documentNumber?: string | null;
  isActive: boolean;
  createdAt: string;
}

export interface CustomerProfileModel extends CustomerListModel {
  birthDate?: string | null;
  updatedAt?: string | null;
}

export interface CustomerAddressModel {
  id: string;
  customerId: string;
  street: string;
  number: string;
  neighborhood: string;
  city: string;
  state: string;
  zipCode: string;
  complement?: string | null;
  referencePoint?: string | null;
  isDefault: boolean;
  createdAt: string;
  updatedAt?: string | null;
}

export type CustomerAppointmentModel = AppointmentListModel;

export interface CustomerDetailModel extends CustomerProfileModel {
  addresses: CustomerAddressModel[];
  appointments: CustomerAppointmentModel[];
}
