import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:loggy/loggy.dart';
import 'package:ouisync/native_channels.dart';
import 'package:ouisync/ouisync.dart' show Session;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../generated/l10n.dart';
import 'cubits/cubits.dart'
    show LocaleCubit, LocaleState, MountCubit, PowerControl, ReposCubit;
import 'pages/pages.dart';
import 'session.dart';
import 'utils/mounter.dart';
import 'utils/platform/platform.dart';
import 'utils/utils.dart';
import 'widgets/media_receiver.dart';

Future<Widget> initOuiSyncApp(List<String> args) async {
  final packageInfo = await PackageInfo.fromPlatform();
  print(packageInfo);

  final windowManager = await PlatformWindowManager.create(
    args,
    packageInfo.appName,
  );
  final session = await createSession(
    packageInfo: packageInfo,
    windowManager: windowManager,
    logger: Loggy<AppLogger>('foreground'),
  );

  final settings = await loadAndMigrateSettings(session);

  final localeCubit = LocaleCubit(settings);

  return BlocProvider<LocaleCubit>(
    create: (context) => localeCubit,
    child: BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, localeState) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _setupAppThemeData(),
        locale: localeState.currentLocale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: OuisyncApp(
          session: session,
          windowManager: windowManager,
          settings: settings,
          packageInfo: packageInfo,
          localeCubit: localeCubit,
        ),
      ),
    ),
  );
}

class OuisyncApp extends StatefulWidget {
  OuisyncApp({
    required this.windowManager,
    required this.session,
    required this.settings,
    required this.packageInfo,
    required this.localeCubit,
    super.key,
  }) : nativeChannels = NativeChannels(session);

  final PlatformWindowManager windowManager;
  final Session session;
  final NativeChannels nativeChannels;
  final Settings settings;
  final PackageInfo packageInfo;
  final LocaleCubit localeCubit;

  @override
  State<OuisyncApp> createState() => _OuisyncAppState();
}

class _OuisyncAppState extends State<OuisyncApp> with AppLogger {
  final receivedMediaController = StreamController<List<SharedMediaFile>>();
  late final powerControl = PowerControl(widget.session, widget.settings);
  late final MountCubit mountCubit;
  late final ReposCubit reposCubit;

  bool get _onboarded =>
      widget.settings.getLocale() != null &&
      !widget.settings.getShowOnboarding() &&
      widget.settings.getEqualitieValues();

  @override
  void initState() {
    super.initState();

    final mounter = Mounter(widget.session);
    mountCubit = MountCubit(mounter)..init();
    reposCubit = ReposCubit(
      session: widget.session,
      nativeChannels: widget.nativeChannels,
      settings: widget.settings,
      cacheServers: CacheServers(Constants.cacheServers),
      mounter: mounter,
    );

    unawaited(_init());
  }

  @override
  void dispose() {
    unawaited(reposCubit.close());
    unawaited(mountCubit.close());
    unawaited(powerControl.close());
    unawaited(receivedMediaController.close());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Visibility(
        child: MediaReceiver(
          controller: receivedMediaController,
          child: MainPage(
            localeCubit: widget.localeCubit,
            mountCubit: mountCubit,
            nativeChannels: widget.nativeChannels,
            packageInfo: widget.packageInfo,
            powerControl: powerControl,
            receivedMedia: receivedMediaController.stream,
            reposCubit: reposCubit,
            session: widget.session,
            settings: widget.settings,
            windowManager: widget.windowManager,
          ),
        ),
        visible: _onboarded,
      );

  Future<void> _init() async {
    await widget.windowManager.setTitle(S.current.messageOuiSyncDesktopTitle);
    await widget.windowManager.initSystemTray();

    // We show the onboarding the first time the app starts.
    // Then, we show the page for accepting eQ values, until the user taps YES.
    // After this, just show the regular home page.

    if (!_onboarded) {
      final onboardingPages = <Widget>[];

      onboardingPages
          .add(LanguagePicker(localeCubit: widget.localeCubit, canPop: false));

      if (widget.settings.getShowOnboarding()) {
        onboardingPages.add(OnboardingPage(settings: widget.settings));
      }

      if (!widget.settings.getEqualitieValues()) {
        // If this is the first time the onboarding page was displayed, even
        // though the setting is already set to true by the time we get to the
        // eQ values page, we can allow the user to navigate back to the
        // onboarding using the back button in Android.
        final canNavigateBack = widget.settings.getShowOnboarding();

        onboardingPages.add(
          AcceptEqualitieValuesTermsPrivacyPage(
            settings: widget.settings,
            canNavigateToOnboarding: canNavigateBack,
          ),
        );
      }

      for (var page in onboardingPages) {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => page))
            .then((result) async {
          if (result == null) return;

          if (result is Locale) {
            await widget.localeCubit.changeLocale(result);
          }
        });
      }

      if (_onboarded) {
        // Force rebuild to show the main page.
        setState(() {});
      }
    }
  }
}

ThemeData _setupAppThemeData() => ThemeData().copyWith(
        appBarTheme: AppBarTheme(),
        focusColor: Colors.black26,
        textTheme: TextTheme().copyWith(
            bodyLarge: AppTypography.bodyBig,
            bodyMedium: AppTypography.bodyMedium,
            bodySmall: AppTypography.bodySmall,
            titleMedium: AppTypography.titleMedium),
        extensions: <ThemeExtension<dynamic>>[
          AppTextThemeExtension(
              titleLarge: AppTypography.titleBig,
              titleMedium: AppTypography.titleMedium,
              titleSmall: AppTypography.titleSmall,
              bodyLarge: AppTypography.bodyBig,
              bodyMedium: AppTypography.bodyMedium,
              bodySmall: AppTypography.bodySmall,
              bodyMicro: AppTypography.bodyMicro,
              labelLarge: AppTypography.labelBig,
              labelMedium: AppTypography.labelMedium,
              labelSmall: AppTypography.labelSmall)
        ]);
