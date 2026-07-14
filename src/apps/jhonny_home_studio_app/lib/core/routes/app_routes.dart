import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/admin_mobile/marketplace/presentation/admin_marketplace_home_screen.dart';
import '../../features/admin_mobile/presentation/admin_mobile_home_screen.dart';
import '../../features/admin_mobile/presentation/admin_mobile_screens.dart';
import '../../features/admin_mobile/presentation/admin_mobile_marketplace_screens.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/addresses/presentation/address_form_screen.dart';
import '../../features/addresses/presentation/addresses_screen.dart';
import '../../features/appointments/presentation/appointment_detail_screen.dart';
import '../../features/appointments/presentation/create_appointment_screen.dart';
import '../../features/appointments/presentation/my_appointments_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/loyalty/presentation/loyalty_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';
import '../../features/marketplace/presentation/product_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/services/presentation/service_detail_screen.dart';
import '../../features/services/presentation/services_screen.dart';
import '../../features/settings/presentation/client_settings_screen.dart';
import '../../features/sos/presentation/sos_loiro_screen.dart';
import '../../features/vip/presentation/vip_club_screen.dart';
import '../../shared/layout/main_shell.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String services = '/services';
  static const String serviceDetail = '/services/:id';
  static const String profile = '/profile';
  static const String clientSettings = '/settings';
  static const String addresses = '/addresses';
  static const String newAddress = '/addresses/new';
  static const String editAddress = '/addresses/:id/edit';
  static const String createAppointment = '/appointments/create';
  static const String createAppointmentByService =
      '/appointments/create/:serviceId';
  static const String myAppointments = '/appointments/my';
  static const String myAppointmentDetail = '/appointments/my/:id';
  static const String vip = '/vip';
  static const String loyalty = '/loyalty';
  static const String sosLoiro = '/sos-loiro';
  static const String marketplace = '/marketplace';
  static const String marketplaceProduct = '/marketplace/products/:id';
  static const String adminMobile = '/admin-mobile';

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final currentLocation = state.uri.path;
        final isLoggedIn = authProvider.isAuthenticated;
        final isAuthPage =
            currentLocation == login || currentLocation == register;
        final isPublicPage = currentLocation == splash || isAuthPage;
        final isAdminPage = currentLocation.startsWith(adminMobile);

        if (!isLoggedIn && !isPublicPage) {
          return login;
        }

        if (isLoggedIn && isAuthPage) {
          return authProvider.isAdmin ? adminMobile : home;
        }

        if (isLoggedIn && currentLocation == splash) {
          return authProvider.isAdmin ? adminMobile : home;
        }

        if (isAdminPage && !authProvider.isAdmin) {
          return '$home?adminRestricted=1';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(path: login, builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: adminMobile,
          builder: (context, state) => const AdminMobileHomeScreen(),
        ),
        GoRoute(
          path: '$adminMobile/services',
          builder: (context, state) =>
              const AdminListScreen(type: AdminListType.services),
        ),
        GoRoute(
          path: '$adminMobile/services/new',
          builder: (context, state) => const AdminServiceFormScreen(),
        ),
        GoRoute(
          path: '$adminMobile/services/:id/edit',
          builder: (context, state) =>
              AdminServiceFormScreen(id: state.pathParameters['id']),
        ),
        GoRoute(
          path: '$adminMobile/appointments',
          builder: (context, state) =>
              const AdminListScreen(type: AdminListType.appointments),
        ),
        GoRoute(
          path: '$adminMobile/appointments/:id',
          builder: (context, state) => AdminAppointmentDetailScreen(
            id: state.pathParameters['id'] ?? '',
          ),
        ),
        GoRoute(
          path: '$adminMobile/customers',
          builder: (context, state) =>
              const AdminListScreen(type: AdminListType.customers),
        ),
        GoRoute(
          path: '$adminMobile/customers/:id',
          builder: (context, state) =>
              AdminCustomerDetailScreen(id: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '$adminMobile/stories',
          builder: (context, state) =>
              const AdminListScreen(type: AdminListType.stories),
        ),
        GoRoute(
          path: '$adminMobile/stories/new',
          builder: (context, state) => const AdminStoryFormScreen(),
        ),
        GoRoute(
          path: '$adminMobile/stories/:id/edit',
          builder: (context, state) =>
              AdminStoryFormScreen(id: state.pathParameters['id']),
        ),
        GoRoute(
          path: '$adminMobile/settings',
          builder: (context, state) => const AdminSettingsScreen(),
        ),
        GoRoute(
          path: '$adminMobile/availability',
          builder: (context, state) => const AdminAvailabilityScreen(),
        ),
        GoRoute(
          path: '$adminMobile/availability/blocked-dates/new',
          builder: (context, state) => const AdminBlockedDateFormScreen(),
        ),
        GoRoute(
          path: '$adminMobile/availability/blocked-dates/:id/edit',
          builder: (context, state) =>
              AdminBlockedDateFormScreen(id: state.pathParameters['id']),
        ),
        GoRoute(
          path: '$adminMobile/marketplace',
          builder: (context, state) => const AdminMarketplaceHomeScreen(),
        ),
        GoRoute(
          path: '$adminMobile/marketplace/products',
          builder: (context, state) =>
              const AdminMarketplaceProductListScreen(),
        ),
        GoRoute(
          path: '$adminMobile/marketplace/products/new',
          builder: (context, state) =>
              const AdminMarketplaceProductFormScreen(),
        ),
        GoRoute(
          path: '$adminMobile/marketplace/products/:id/edit',
          builder: (context, state) =>
              AdminMarketplaceProductFormScreen(id: state.pathParameters['id']),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(currentPath: state.uri.path, child: child);
          },
          routes: [
            GoRoute(
              path: home,
              builder: (context, state) => HomeScreen(
                showAdminRestrictedMessage:
                    state.uri.queryParameters['adminRestricted'] == '1',
              ),
            ),
            GoRoute(
              path: services,
              builder: (context, state) => const ServicesScreen(),
            ),
            GoRoute(
              path: serviceDetail,
              builder: (context, state) {
                final serviceId = state.pathParameters['id'] ?? '';
                return ServiceDetailScreen(serviceId: serviceId);
              },
            ),
            GoRoute(
              path: profile,
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: clientSettings,
              builder: (context, state) => const ClientSettingsScreen(),
            ),
            GoRoute(
              path: addresses,
              builder: (context, state) => const AddressesScreen(),
            ),
            GoRoute(
              path: newAddress,
              builder: (context, state) => const AddressFormScreen(),
            ),
            GoRoute(
              path: editAddress,
              builder: (context, state) {
                final addressId = state.pathParameters['id'] ?? '';
                return AddressFormScreen(addressId: addressId);
              },
            ),
            GoRoute(
              path: createAppointment,
              builder: (context, state) => const CreateAppointmentScreen(),
            ),
            GoRoute(
              path: createAppointmentByService,
              builder: (context, state) {
                final serviceId = state.pathParameters['serviceId'];
                return CreateAppointmentScreen(serviceId: serviceId);
              },
            ),
            GoRoute(
              path: myAppointments,
              builder: (context, state) => const MyAppointmentsScreen(),
            ),
            GoRoute(
              path: myAppointmentDetail,
              builder: (context, state) {
                final appointmentId = state.pathParameters['id'] ?? '';
                return AppointmentDetailScreen(appointmentId: appointmentId);
              },
            ),
            GoRoute(
              path: vip,
              builder: (context, state) => const VipClubScreen(),
            ),
            GoRoute(
              path: loyalty,
              builder: (context, state) => const LoyaltyScreen(),
            ),
            GoRoute(
              path: sosLoiro,
              builder: (context, state) => const SosLoiroScreen(),
            ),
            GoRoute(
              path: marketplace,
              builder: (context, state) => const MarketplaceScreen(),
            ),
            GoRoute(
              path: marketplaceProduct,
              builder: (context, state) => ProductDetailScreen(
                productId: state.pathParameters['id'] ?? '',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
