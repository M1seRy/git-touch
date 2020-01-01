import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:git_touch/graphql/github_user.dart';
import 'package:git_touch/models/theme.dart';
import 'package:git_touch/scaffolds/refresh_stateful.dart';
import 'package:git_touch/screens/users.dart';
import 'package:git_touch/utils/utils.dart';
import 'package:git_touch/widgets/app_bar_title.dart';
import 'package:git_touch/screens/repositories.dart';
import 'package:git_touch/widgets/entry_item.dart';
import 'package:git_touch/widgets/repository_item.dart';
import 'package:git_touch/widgets/table_view.dart';
import 'package:git_touch/widgets/text_contains_organization.dart';
import 'package:git_touch/widgets/user_item.dart';
import 'package:git_touch/models/auth.dart';
import 'package:provider/provider.dart';
import 'package:git_touch/widgets/action_button.dart';

final userRouter = RouterScreen(
  '/:login',
  (context, parameters) {
    final login = parameters['login'].first;
    final tab = parameters['tab']?.first;
    switch (tab) {
      case 'followers':
        return UsersScreen(login, UsersScreenType.follower);
      case 'following':
        return UsersScreen(login, UsersScreenType.following);
      case 'people':
        return UsersScreen(login, UsersScreenType.member);
      case 'stars':
        return RepositoriesScreen.stars(login);
      case 'repositories':
        return RepositoriesScreen(login);
      default:
        return UserScreen(login);
    }
  },
);

class UserScreen extends StatelessWidget {
  final String login;

  UserScreen(this.login);

  Iterable<Widget> _buildPinnedItems(Iterable<GithubUserRepository> pinnedItems,
      Iterable<GithubUserRepository> repositories) {
    String title;
    Iterable<GithubUserRepository> items = [];

    if (pinnedItems.isNotEmpty) {
      title = 'pinned repositories';
      items = pinnedItems;
    } else if (repositories.isNotEmpty) {
      title = 'popular repositories';
      items = repositories;
    }
    if (items.isEmpty) return [];

    return [
      CommonStyle.verticalGap,
      if (title != null) TableViewHeader(title),
      ...join(
        CommonStyle.border,
        items.map((item) {
          return RepositoryItem.github(item);
        }).toList(),
      ),
    ];
  }

  Widget _buildUser(BuildContext context, GithubUserUser user) {
    final theme = Provider.of<ThemeModel>(context);
    final login = user.login;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UserItem(
          login: user.login,
          name: user.name,
          avatarUrl: user.avatarUrl,
          bio: user.bio,
          inUserScreen: true,
        ),
        CommonStyle.border,
        Row(children: [
          EntryItem(
            count: user.repositories.totalCount,
            text: 'Repositories',
            url: '/$login?tab=repositories',
          ),
          EntryItem(
            count: user.starredRepositories.totalCount,
            text: 'Stars',
            url: '/$login?tab=stars',
          ),
          EntryItem(
            count: user.followers.totalCount,
            text: 'Followers',
            url: '/$login?tab=followers',
          ),
          EntryItem(
            count: user.following.totalCount,
            text: 'Following',
            url: '/$login?tab=following',
          ),
        ]),
        CommonStyle.verticalGap,
        Container(
          color: theme.palette.background,
          padding: CommonStyle.padding,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Wrap(
              spacing: 3,
              children: user.contributionsCollection.contributionCalendar.weeks
                  .map((week) {
                return Wrap(
                  direction: Axis.vertical,
                  spacing: 3,
                  children: week.contributionDays.map((day) {
                    var color = convertColor(day.color);
                    if (theme.brightness == Brightness.dark) {
                      color = Color.fromRGBO(0xff - color.red,
                          0xff - color.green, 0xff - color.blue, 1);
                    }
                    return SizedBox(
                      width: 10,
                      height: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: color),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
        CommonStyle.verticalGap,
        TableView(
          hasIcon: true,
          items: [
            if (isNotNullOrEmpty(user.company))
              TableViewItem(
                leftIconData: Octicons.organization,
                text: TextContainsOrganization(
                  user.company,
                  style: TextStyle(fontSize: 16, color: theme.palette.text),
                  oneLine: true,
                ),
              ),
            if (isNotNullOrEmpty(user.location))
              TableViewItem(
                leftIconData: Octicons.location,
                text: Text(user.location),
                onTap: () {
                  launchUrl('https://www.google.com/maps/place/' +
                      user.location.replaceAll(RegExp(r'\s+'), ''));
                },
              ),
            if (isNotNullOrEmpty(user.email))
              TableViewItem(
                leftIconData: Octicons.mail,
                text: Text(user.email),
                onTap: () {
                  launchUrl('mailto:' + user.email);
                },
              ),
            if (isNotNullOrEmpty(user.websiteUrl))
              TableViewItem(
                leftIconData: Octicons.link,
                text: Text(user.websiteUrl),
                onTap: () {
                  var url = user.websiteUrl;
                  if (!url.startsWith('http')) {
                    url = 'http://$url';
                  }
                  launchUrl(url);
                },
              ),
          ],
        ),
        ..._buildPinnedItems(
            user.pinnedItems.nodes
                .where((n) => n is GithubUserRepository)
                .cast<GithubUserRepository>(),
            user.repositories.nodes),
        CommonStyle.verticalGap,
      ],
    );
  }

  Widget _buildOrganization(
      BuildContext context, GithubUserOrganization payload) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UserItem(
          login: payload.login,
          name: payload.name,
          avatarUrl: payload.avatarUrl,
          bio: payload.description,
          inUserScreen: true,
        ),
        CommonStyle.border,
        Row(children: [
          EntryItem(
            count: payload.pinnableItems.totalCount,
            text: 'Repositories',
            url: '/$login?tab=repositories',
          ),
          EntryItem(
            count: payload.membersWithRole.totalCount,
            text: 'Members',
            url: '/$login?tab=people',
          ),
        ]),
        CommonStyle.verticalGap,
        TableView(
          hasIcon: true,
          items: [
            if (isNotNullOrEmpty(payload.location))
              TableViewItem(
                leftIconData: Octicons.location,
                text: Text(payload.location),
                onTap: () {
                  launchUrl('https://www.google.com/maps/place/' +
                      payload.location.replaceAll(RegExp(r'\s+'), ''));
                },
              ),
            if (isNotNullOrEmpty(payload.email))
              TableViewItem(
                leftIconData: Octicons.mail,
                text: Text(payload.email),
                onTap: () {
                  launchUrl('mailto:' + payload.email);
                },
              ),
            if (isNotNullOrEmpty(payload.websiteUrl))
              TableViewItem(
                leftIconData: Octicons.link,
                text: Text(payload.websiteUrl),
                onTap: () {
                  var url = payload.websiteUrl;
                  if (!url.startsWith('http')) {
                    url = 'http://$url';
                  }
                  launchUrl(url);
                },
              ),
          ],
        ),
        ..._buildPinnedItems(
          payload.pinnedItems.nodes
              .where((n) => n is GithubUserRepository)
              .cast<GithubUserRepository>(),
          payload.pinnableItems.nodes
              .where((n) => n is GithubUserRepository)
              .cast<GithubUserRepository>(),
        ),
        CommonStyle.verticalGap,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshStatefulScaffold<GithubUserRepositoryOwner>(
      fetchData: () async {
        final data = await Provider.of<AuthModel>(context).gqlClient.execute(
            GithubUserQuery(variables: GithubUserArguments(login: login)));
        return data.data.repositoryOwner;
      },
      title: AppBarTitle('User'), // TODO:
      actionBuilder: (payload, _) {
        if (payload == null)
          return ActionButton(
            title: "Actions",
            items: [],
          );

        switch (payload.resolveType) {
          case 'User':
            final user = payload as GithubUserUser;
            return ActionButton(
              title: 'User Actions',
              items: [
                if (user.viewerCanFollow)
                  ActionItem(
                    text: user.viewerIsFollowing ? 'Unfollow' : 'Follow',
                    onPress: (_) async {
                      if (user.viewerIsFollowing) {
                        await Provider.of<AuthModel>(context)
                            .deleteWithCredentials('/user/following/$login');
                        user.viewerIsFollowing = false;
                      } else {
                        Provider.of<AuthModel>(context)
                            .putWithCredentials('/user/following/$login');
                        user.viewerIsFollowing = true;
                      }
                    },
                  ),
                if (payload != null) ...[
                  ActionItem.share(user.url),
                  ActionItem.launch(user.url),
                ],
              ],
            );
          case 'Organization':
            final organization = payload as GithubUserOrganization;
            return ActionButton(
              title: 'Organization Actions',
              items: [
                if (payload != null) ...[
                  ActionItem.share(organization.url),
                  ActionItem.launch(organization.url),
                ],
              ],
            );
          default:
            return null;
        }
      },
      bodyBuilder: (payload, _) {
        switch (payload.resolveType) {
          case 'User':
            return _buildUser(context, payload as GithubUserUser);
          case 'Organization':
            return _buildOrganization(
                context, payload as GithubUserOrganization);
          default:
            return null;
        }
      },
    );
  }
}
