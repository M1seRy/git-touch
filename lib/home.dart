import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:git_touch/models/auth.dart';
import 'package:git_touch/models/notification.dart';
import 'package:git_touch/models/theme.dart';
import 'package:git_touch/screens/bb_explore.dart';
import 'package:git_touch/screens/bb_teams.dart';
import 'package:git_touch/screens/bb_user.dart';
import 'package:git_touch/screens/gt_orgs.dart';
import 'package:git_touch/screens/gt_user.dart';
import 'package:git_touch/screens/gl_explore.dart';
import 'package:git_touch/screens/gl_groups.dart';
import 'package:git_touch/screens/gl_user.dart';
import 'package:git_touch/screens/login.dart';
import 'package:git_touch/screens/gh_notification.dart';
import 'package:git_touch/screens/gh_user.dart';
import 'package:git_touch/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:git_touch/screens/gh_news.dart';
import 'package:git_touch/screens/gh_search.dart';
import 'package:git_touch/screens/gh_trending.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Created 5 different variables instead of a list as list doesn't work
  final GlobalKey<NavigatorState> tab1 = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> tab2 = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> tab3 = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> tab4 = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> tab5 = GlobalKey<NavigatorState>();
  final CupertinoTabController _controller = CupertinoTabController();

  _buildScreen(int index) {
    // return GlProjectScreen(32221);
    // return IssuesScreen('flutter', 'flutter', isPullRequest: true);
    // return IssueScreen('reactjs', 'rfcs', 29);
    // return IssueScreen('reactjs', 'rfcs', 68, isPullRequest: true);
    // return Image.asset('images/spinner.webp', width: 32, height: 32);
    final auth = Provider.of<AuthModel>(context);
    switch (auth.activeAccount.platform) {
      case PlatformType.github:
        switch (index) {
          case 0:
            return GhNewsScreen();
          case 1:
            return GhNotificationScreen();
          case 2:
            return GhTrendingScreen();
          case 3:
            return GhSearchScreen();
          case 4:
            return GhUserScreen(null);
        }
        break;
      case PlatformType.gitlab:
        switch (index) {
          case 0:
            return GlExploreScreen();
          case 1:
            return GlGroupsScreenn();
          case 2:
            return GlUserScreen(null);
        }
        break;
      case PlatformType.bitbucket:
        switch (index) {
          case 0:
            return BbExploreScreen();
          case 1:
            return BbTeamsScreen();
          case 2:
            return BbUserScreen(null);
        }
        break;
      case PlatformType.gitea:
        switch (index) {
          case 0:
            return GtOrgsScreen();
          case 1:
            return GtUserScreen(null);
        }
        break;
    }
  }

  Widget _buildNotificationIcon(BuildContext context, bool isActive) {
    final theme = Provider.of<ThemeModel>(context);
    final iconData = Icons.notifications;
    int count = Provider.of<NotificationModel>(context).count;
    if (count == 0) {
      return Icon(iconData);
    }

    // String text = count > 99 ? '99+' : count.toString();
    return Stack(
      children: <Widget>[
        Icon(iconData),
        Positioned(
            right: -2,
            top: -2,
            child: Icon(Octicons.primitive_dot,
                color: theme.palette.primary, size: 14))
      ],
    );
  }

  List<BottomNavigationBarItem> get _navigationItems {
    switch (Provider.of<AuthModel>(context).activeAccount.platform) {
      case PlatformType.github:
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed),
            title: Text('News'),
          ),
          BottomNavigationBarItem(
            icon: _buildNotificationIcon(context, false),
            activeIcon: _buildNotificationIcon(context, true),
            title: Text('Notification'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot),
            title: Text('Trending'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            title: Text('Search'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            activeIcon: Icon(Icons.person),
            title: Text('Me'),
          ),
        ];
      case PlatformType.gitlab:
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            title: Text('Explore'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            title: Text('Groups'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Me'),
          ),
        ];
      case PlatformType.bitbucket:
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            title: Text('Explore'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            title: Text('Teams'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Me'),
          ),
        ];
      case PlatformType.gitea:
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            title: Text('Organizations'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Me'),
          ),
        ];
    }
  }

  GlobalKey<NavigatorState> getNavigatorKey(int index) {
    switch (index) {
      case 0:
        return tab1;
      case 1:
        return tab2;
      case 2:
        return tab3;
      case 3:
        return tab4;
      case 4:
        return tab5;
    }
    return tab1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeModel>(context);
    final auth = Provider.of<AuthModel>(context);

    if (auth.activeAccount == null) {
      return LoginScreen();
    }

    switch (auth.activeAccount.platform) {
      case PlatformType.github:
        theme.setActiveTab(theme.startTabGh);
        break;
      case PlatformType.gitlab:
        theme.setActiveTab(theme.startTabGl);
        break;
      case PlatformType.bitbucket:
        theme.setActiveTab(theme.startTabBb);
        break;
      case PlatformType.gitea:
        theme.setActiveTab(theme.startTabGt);
        break;
    }

    _controller.index = theme.active;

    switch (theme.theme) {
      case AppThemeType.cupertino:
        return WillPopScope(
            onWillPop: () async {
              return !await getNavigatorKey(_controller.index)
                  .currentState
                  .maybePop();
            },
            child: CupertinoTabScaffold(
                controller: _controller,
                tabBuilder: (context, index) {
                  return CupertinoTabView(
                      navigatorKey: getNavigatorKey(index),
                      builder: (context) {
                        return _buildScreen(index);
                      });
                },
                tabBar: CupertinoTabBar(
                    items: _navigationItems,
                    currentIndex: _controller.index,
                    onTap: (index) {
                      if (theme.active == index) {
                        getNavigatorKey(index)
                            .currentState
                            .popUntil((route) => route.isFirst);
                      }
                      theme.setActiveTab(index);
                      switch (auth.activeAccount.platform) {
                        case PlatformType.github:
                          theme.setDefaultStartTabGh(index);
                          break;
                        case PlatformType.gitlab:
                          theme.setDefaultStartTabGl(index);
                          break;
                        case PlatformType.bitbucket:
                          theme.setDefaultStartTabBb(index);
                          break;
                        case PlatformType.gitea:
                          theme.setDefaultStartTabGt(index);
                          break;
                      }
                    })));
      default:
        return Scaffold(
          body: _buildScreen(theme.active),
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: theme.palette.primary,
            items: _navigationItems,
            currentIndex: theme.active,
            type: BottomNavigationBarType.fixed,
            onTap: (int index) {
              switch (auth.activeAccount.platform) {
                case PlatformType.github:
                  theme.setDefaultStartTabGh(index);
                  break;
                case PlatformType.gitlab:
                  theme.setDefaultStartTabGl(index);
                  break;
                case PlatformType.bitbucket:
                  theme.setDefaultStartTabBb(index);
                  break;
                case PlatformType.gitea:
                  theme.setDefaultStartTabGt(index);
                  break;
              }
              setState(() {
                theme.setActiveTab(index);
              });
            },
          ),
        );
    }
  }
}
