import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/refresh_scaffold.dart';
import '../providers/notification.dart';
import '../providers/settings.dart';
import '../widgets/notification_item.dart';
import '../widgets/list_group.dart';
import '../widgets/link.dart';
import '../utils/utils.dart';

String getRepoKey(NotificationGroup group) {
  return ('_' + group.owner + '_' + group.name).replaceAll('-', '__');
}

String getItemKey(NotificationPayload item) {
  return '_' + item.number.toString();
}

class NotificationGroup {
  String owner;
  String name;
  get repo => owner + '/' + name;
  List<NotificationPayload> items = [];

  NotificationGroup(this.owner, this.name);
}

class NotificationScreen extends StatefulWidget {
  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen> {
  int active = 0;
  bool loading;
  Map<String, NotificationGroup> groupMap = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<Map<String, NotificationGroup>> fetchNotifications(int index) async {
    List items = await SettingsProvider.of(context).getWithCredentials(
        '/notifications?all=${index == 2}&participating=${index == 1}');
    var ns = items.map((item) => NotificationPayload.fromJson(item)).toList();

    if (index == 0) {
      NotificationProvider.of(context).setCount(ns.length);
    }

    Map<String, NotificationGroup> _groupMap = {};

    ns.forEach((item) {
      String repo = item.owner + '/' + item.name;
      if (_groupMap[repo] == null) {
        _groupMap[repo] = NotificationGroup(item.owner, item.name);
      }

      _groupMap[repo].items.add(item);
    });

    if (_groupMap.isNotEmpty) {
      // query state of issues and pull requests
      var schema = '{';
      _groupMap.forEach((repo, group) {
        var repoKey = getRepoKey(group);
        schema +=
            '$repoKey: repository(owner: "${group.owner}", name: "${group.name}") {';

        group.items.forEach((item) {
          var key = getItemKey(item);

          switch (item.type) {
            case 'Issue':
              schema += '''
$key: issue(number: ${item.number}) {
  state
}
''';
              break;
            case 'PullRequest':
              schema += '''
$key: pullRequest(number: ${item.number}) {
  state
}
''';
              break;
          }
        });

        schema += '}';
      });
      schema += '}';

      // print(schema);
      var data = await SettingsProvider.of(context).query(schema);
      _groupMap.forEach((repo, group) {
        group.items.forEach((item) {
          var itemData = data[getRepoKey(group)][getItemKey(item)];
          if (itemData != null) {
            item.state = itemData['state'];
          }
        });
      });
      // print(data);
    }

    return _groupMap;
  }

  Widget _buildGroupItem(
      BuildContext context, MapEntry<String, NotificationGroup> entry) {
    var group = entry.value;
    var repo = group.repo;
    return ListGroup(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              repo,
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
            Link(
              beforeRedirect: () async {
                await SettingsProvider.of(context)
                    .putWithCredentials('/repos/$repo/notifications');
                await _refresh();
              },
              child: Icon(
                Octicons.check,
                color: Colors.black45,
                size: 20,
              ),
            ),
          ],
        ),
        items: group.items,
        itemBuilder: (item, index) {
          return NotificationItem(
            payload: item,
            markAsRead: () {
              setState(() {
                groupMap[entry.key].items[index].unread = false;
              });
            },
          );
        });
  }

  Future<void> _onSwitchTab(int index) async {
    setState(() {
      active = index;
      loading = true;
    });

    var _groupMap = await fetchNotifications(active);

    if (mounted) {
      setState(() {
        groupMap = _groupMap;
        loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    // setState(() {});
    await _onSwitchTab(active);
  }

  var textMap = {
    0: 'Unread',
    1: 'Paticipating',
    2: 'All',
  };

  // var iconMap = {
  //   0: Icon(Icons.inbox),
  //   1: Icon(Icons.group),
  //   2: Icon(Icons.mail),
  // };

  @override
  Widget build(context) {
    return RefreshScaffold(
      title: Text(textMap[active]),
      trailing: GestureDetector(
        child: Icon(Icons.more_vert, size: 20),
        onTap: () async {
          int value = await showCupertinoDialog(
            context: context,
            builder: (context) {
              return CupertinoAlertDialog(
                title: Text('Select filter'),
                actions: textMap.entries.map((entry) {
                  return CupertinoDialogAction(
                    child: Text(entry.value),
                    onPressed: () {
                      Navigator.pop(context, entry.key);
                    },
                  );
                }).toList(),
              );
            },
          );
          _onSwitchTab(value);
        },
      ),
      actions: <Widget>[
        PopupMenuButton(
          onSelected: (value) {
            _onSwitchTab(value);
          },
          itemBuilder: (context) {
            return textMap.entries.map((entry) {
              return PopupMenuItem(value: entry.key, child: Text(entry.value));
            }).toList();
          },
        )
      ],
      onRefresh: _refresh,
      loading: loading,
      bodyBuilder: () {
        return Column(
            children: groupMap.entries
                .map((entry) => _buildGroupItem(context, entry))
                .toList());
      },
    );
  }
}