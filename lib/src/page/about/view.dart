import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/widget/text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../base/baseBottomNavigationItemPage.dart';

class AboutPage extends BaseBottomNavigationItemPage {
  AboutPage() {
    title = 'about';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        children: [
          card('このアプリについて', () {
            showAboutDialog(
                context: context,
                applicationName: '点数表',
                applicationLegalese: '2022 masatesu');
          }),
          card('お問い合せ', () {
            showDialog<void>(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: NormalText('twitterからメールにてお問い合わせください。'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(
                        child: NormalText('twitterを開く'),
                        onPressed: () async {
                          final url = 'twitter://user?screen_name=TwitterJP';
                          var uri = Uri.parse(url);
                          final result = await canLaunchUrl(uri);
                          if (!result) {
                            uri = Uri.parse('https://twitter.com/TwitterJP');
                          }

                          await launchUrl(uri);
                        },
                      ),
                      TextButton(
                        child: NormalText('メーラーを開く'),
                        onPressed: () async {
                          final title = Uri.encodeComponent('点数表の問い合わせ');
                          final body = Uri.encodeComponent('お問合せ内容を以下にご記入ください。'
                              '不具合のご指摘の場合、状況がわかるようなスクリーンショットを添付していただくと、ご案内がスムーズになります');
                          const mailAddress = 'xxx@gmail.com'; //メールアドレス

                          final uri = Uri.parse(
                              'mailto:$mailAddress?subject=$title&body=$body');

                          final result = await canLaunchUrl(uri);
                          if (!result) {
                            // TODO
                          }
                          launchUrl(uri);
                        },
                      ),
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const NormalText('閉じる'))
                    ],
                  );
                });
          }),
        ],
      ),
    );
  }
}

Widget card(String title, GestureTapCallback onTap) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
    child: InkWell(
      child: Card(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          side: BorderSide(
            color: Colors.black,
          ),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: ListTile(
            title: NormalText(title),
          ),
        ),
      ),
      onTap: onTap,
    ),
  );
}
