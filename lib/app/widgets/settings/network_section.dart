import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';

import '../../../generated/l10n.dart';
import '../../cubits/cubits.dart';
import '../../pages/peers_page.dart';
import '../../utils/utils.dart';
import '../long_text.dart';
import '../widgets.dart';
import 'settings_section.dart';
import 'settings_tile.dart';

class NetworkSection extends SettingsSection {
  NetworkSection(
    this.session,
    this.cubits, {
    required this.connectivityInfo,
    required this.natDetection,
    required this.peerSet,
  }) : super(
          key: GlobalKey(debugLabel: 'key_network_section'),
          title: S.current.titleNetwork,
        );

  final Session session;
  final Cubits cubits;
  final ConnectivityInfo connectivityInfo;
  final NatDetection natDetection;
  final PeerSetCubit peerSet;

  TextStyle? bodyStyle;
  TextStyle? subtitleStyle;

  @override
  List<Widget> buildTiles(BuildContext context) {
    bodyStyle = context.theme.appTextStyle.bodyMedium;
    subtitleStyle = context.theme.appTextStyle.bodySmall;

    return [
      _buildConnectivityTypeTile(context),
      _buildPortForwardingTile(context),
      _buildLocalDiscoveryTile(context),
      _buildSyncOnMobileSwitch(context),
      ..._buildConnectivityInfoTiles(context),
      _buildPeerListTile(context),
      _buildNatDetectionTile(context),
    ];
  }

  Widget _buildConnectivityTypeTile(BuildContext context) =>
      BlocBuilder<PowerControl, PowerControlState>(
        bloc: cubits.powerControl,
        builder: (context, state) => SettingsTile(
          leading: Icon(Icons.wifi),
          title: Text(S.current.labelConnectionType, style: bodyStyle),
          value: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_connectivityTypeName(state.connectivityType),
                  style: subtitleStyle),
              if (state.networkDisabledReason != null)
                Text('(${state.networkDisabledReason!})', style: subtitleStyle),
            ],
          ),
          trailing: (state.isNetworkEnabled ?? true)
              ? null
              : Icon(Icons.warning, color: Constants.warningColor),
        ),
      );

  Widget _buildPortForwardingTile(BuildContext context) =>
      BlocSelector<PowerControl, PowerControlState, bool>(
        bloc: cubits.powerControl,
        selector: (state) => state.portForwardingEnabled,
        builder: (context, value) => SwitchSettingsTile(
            value: value,
            onChanged: (value) {
              unawaited(cubits.powerControl.setPortForwardingEnabled(value));
            },
            title: InfoBuble(
                child: Text(Strings.upNP, style: bodyStyle),
                title: S.current.titleUPnP,
                description: [TextSpan(text: S.current.messageInfoUPnP)]),
            leading: Icon(Icons.router)),
      );

  Widget _buildLocalDiscoveryTile(BuildContext context) =>
      BlocSelector<PowerControl, PowerControlState, bool>(
        bloc: cubits.powerControl,
        selector: (state) => state.localDiscoveryEnabled,
        builder: (context, value) => SwitchSettingsTile(
          value: value,
          onChanged: (value) {
            unawaited(cubits.powerControl.setLocalDiscoveryEnabled(value));
          },
          title: InfoBuble(
              child: Text(S.current.messageLocalDiscovery, style: bodyStyle),
              title: S.current.messageLocalDiscovery,
              description: [
                TextSpan(text: S.current.messageInfoLocalDiscovery)
              ]),
          leading: Icon(Icons.broadcast_on_personal),
        ),
      );

  Widget _buildSyncOnMobileSwitch(BuildContext context) =>
      BlocSelector<PowerControl, PowerControlState, bool>(
        bloc: cubits.powerControl,
        selector: (state) => state.syncOnMobile,
        builder: (context, value) => SwitchSettingsTile(
          value: value,
          onChanged: (value) {
            unawaited(cubits.powerControl.setSyncOnMobileEnabled(value));
          },
          title: InfoBuble(
              child: Text(S.current.messageSyncMobileData, style: bodyStyle),
              title: S.current.messageSyncMobileData,
              description: [
                TextSpan(text: S.current.messageInfoSyncMobileData)
              ]),
          leading: Icon(Icons.mobile_screen_share),
        ),
      );

  List<Widget> _buildConnectivityInfoTiles(BuildContext context) => [
        _buildConnectivityInfoTile(
          S.current.labelTcpListenerEndpointV4,
          Icons.computer,
          (state) => state.tcpListenerV4,
        ),
        _buildConnectivityInfoTile(
          S.current.labelTcpListenerEndpointV6,
          Icons.computer,
          (state) => state.tcpListenerV6,
        ),
        _buildConnectivityInfoTile(
          S.current.labelQuicListenerEndpointV4,
          Icons.computer,
          (state) => state.quicListenerV4,
        ),
        _buildConnectivityInfoTile(
          S.current.labelQuicListenerEndpointV6,
          Icons.computer,
          (state) => state.quicListenerV6,
        ),
        _buildAddressesTile(
          S.current.labelExternalAddresses,
          Icons.cloud_outlined,
          (state) => state.externalAddresses,
        ),
        _buildAddressesTile(
          S.current.labelLocalAddresses,
          Icons.lan_outlined,
          (state) => state.localAddresses,
        ),
      ];

  Widget _buildConnectivityInfoTile(
    String title,
    IconData icon,
    String Function(ConnectivityInfoState) selector,
  ) =>
      BlocSelector<ConnectivityInfo, ConnectivityInfoState, String>(
          bloc: connectivityInfo,
          selector: selector,
          builder: (context, value) {
            if (value.isNotEmpty) {
              return SettingsTile(
                leading: Icon(icon),
                title: Text(title, style: bodyStyle),
                value: Text(value, style: subtitleStyle),
              );
            } else {
              return SizedBox.shrink();
            }
          });

  Widget _buildAddressesTile(
    String title,
    IconData icon,
    List<String> Function(ConnectivityInfoState) selector,
  ) =>
      BlocSelector<ConnectivityInfo, ConnectivityInfoState, List<String>>(
          bloc: connectivityInfo,
          selector: selector,
          builder: (context, list) {
            if (list.isNotEmpty) {
              return SettingsTile(
                leading: Icon(icon),
                title: Text(title, style: bodyStyle),
                value: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: list
                      .map(
                        (address) => _AddressWidget(
                          address,
                          style: subtitleStyle,
                        ),
                      )
                      .toList(),
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          });

  Widget _buildPeerListTile(BuildContext context) =>
      BlocBuilder<PeerSetCubit, PeerSet>(
        bloc: peerSet,
        builder: (context, state) => NavigationTile(
            leading: Icon(Icons.people),
            title: Text(S.current.labelPeers, style: bodyStyle),
            value: Text(state.numConnected.toString(), style: subtitleStyle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PeersPage(session, peerSet),
                ),
              );
            }),
      );

  Widget _buildNatDetectionTile(BuildContext context) =>
      BlocBuilder<NatDetection, NatDetectionType>(
        bloc: natDetection,
        builder: (context, type) => SettingsTile(
          leading: Icon(Icons.nat),
          title: InfoBuble(
              child: Text(S.current.messageNATType, style: bodyStyle),
              title: S.current.messageNATType,
              description: [
                TextSpan(text: S.current.messageInfoNATType),
                Fields.linkTextSpan(
                    context,
                    '\n\n${S.current.messageNATOnWikipedia}',
                    _launchNATOnWikipedia)
              ]),
          value: Text(type.message(), style: subtitleStyle),
        ),
      );

  void _launchNATOnWikipedia(BuildContext context) async {
    final title = Text(S.current.messageNATOnWikipedia);
    await Fields.openUrl(context, title, Constants.natWikipediaUrl);
  }
}

String _connectivityTypeName(ConnectivityResult result) {
  switch (result) {
    case ConnectivityResult.bluetooth:
      return S.current.messageBluetooth;
    case ConnectivityResult.wifi:
      return S.current.messageWiFi;
    case ConnectivityResult.mobile:
      return S.current.messageMobile;
    case ConnectivityResult.ethernet:
      return S.current.messageEthernet;
    case ConnectivityResult.vpn:
      return S.current.messageVPN;
    case ConnectivityResult.none:
      return S.current.messageNone;
    case ConnectivityResult.other:
      return 'other';
  }
}

class _AddressWidget extends StatelessWidget {
  final String address;
  final TextStyle? style;

  const _AddressWidget(this.address, {this.style});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: SelectionArea(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(address, style: style),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy),
            iconSize: style?.fontSize,
            visualDensity: VisualDensity.compact,
            onPressed: () => _onPressed(context),
          )
        ],
      );

  Future<void> _onPressed(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: address));
    showSnackBar(context, message: S.current.messageCopiedToClipboard);
  }
}
