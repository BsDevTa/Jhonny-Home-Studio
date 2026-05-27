namespace JhonnyHomeStudio.Application.Common.Dtos.Appointments;

public sealed class UpdateAppointmentStatusRequest
{
    public string Status { get; set; } = string.Empty;
    public string? Note { get; set; }
}