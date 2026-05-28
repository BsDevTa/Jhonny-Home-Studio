bool isServicesPath(String path) {
  return path == '/services' || path.startsWith('/services/');
}

bool isAppointmentsPath(String path) {
  return path == '/appointments/create' ||
      path.startsWith('/appointments/create/') ||
      path == '/appointments/my' ||
      path.startsWith('/appointments/my/');
}

bool isProfilePath(String path) {
  return path == '/profile' || path.startsWith('/addresses');
}

int getBottomNavIndex(String path) {
  if (isAppointmentsPath(path)) {
    return 2;
  }

  if (isServicesPath(path)) {
    return 1;
  }

  if (isProfilePath(path)) {
    return 3;
  }

  return 0;
}
