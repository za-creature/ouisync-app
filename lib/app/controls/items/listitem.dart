import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../models/models.dart';
import '../controls.dart';

class ListItem extends StatelessWidget {
  const ListItem({
    required this.itemData,
    required this.mainAction,
    required this.popupAction,
    this.isEncrypted = false,
    this.isLocal = true,
    this.isOwn = true,
  });

  final BaseItem itemData;
  final Function mainAction;
  final Function popupAction;
  final bool isEncrypted;
  final bool isLocal;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final container = Material(
      child: InkWell(
        onTap:() => mainAction.call(),
        splashColor: Colors.blue,
        child: Container(
          padding: EdgeInsets.fromLTRB(8.0, 10.0, 2.0, 15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _getIconByType(),
              _getExpandedDescriptionByType(),
              _getActionByType(popupAction),
            ],
          ),
        )
      ),
      color: _getColor(),
    );

    return itemData.itemType == ItemType.folder
        ? Card(child: container)
        : container;
  }

  Color _getColor() {
    return itemData.itemType == ItemType.file
      ? Colors.transparent
      : Color.fromARGB(35, 220, 220, 220);
  }

  Widget _getIconByType() {
    return itemData.itemType == ItemType.folder
      ? Container()
      : Icon(itemData.icon);
  }

  Expanded _getExpandedDescriptionByType() {
    return Expanded(
      flex: 1,
      child: itemData.itemType == ItemType.repo
        ? RepoDescription(
          folderData: itemData,
          isEncrypted: isEncrypted,
          isLocal: isLocal,
          isOwn: isOwn,
          action: mainAction
        )
        : itemData.itemType == ItemType.folder
        ? FolderDescription(folderData: itemData)
        : FileDescription(fileData: itemData)
    );
  }

  IconButton _getActionByType(Function action) {
    return itemData.itemType == ItemType.file
        ? IconButton(icon: const Icon(Icons.more_vert, size: 24.0,), onPressed: () => action.call())
        : IconButton(onPressed: null, icon: Container());
  }

}