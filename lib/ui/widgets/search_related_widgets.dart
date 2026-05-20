import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/Search/search_result_screen_controller.dart';
import '/models/album.dart';
import '/models/artist.dart';
import '/models/playlist.dart';
import '/ui/widgets/content_list_widget.dart';
import 'separate_tab_item_widget.dart';

class ResultWidget extends StatelessWidget {
  const ResultWidget({super.key, this.isv2Used = false});
  final bool isv2Used;

  @override
  Widget build(BuildContext context) {
    final SearchResultScreenController searchResScrController =
        Get.find<SearchResultScreenController>();
    final topPadding = context.isLandscape ? 50.0 : 80.0;
    return Obx(
      () => Center(
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: SingleChildScrollView(
            padding:
                EdgeInsets.only(bottom: 200, top: isv2Used ? 0 : topPadding),
            child: searchResScrController.isResultContentFetced.value
                ? Column(children: [
                    if (!isv2Used)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "searchRes".tr,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    if (!isv2Used)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${"for1".tr} \"${searchResScrController.queryString.value}\"",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    ...generateWidgetList(context, searchResScrController),
                  ])
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  List<Widget> generateWidgetList(
      BuildContext context, SearchResultScreenController searchResScrController) {
    List<Widget> songsList = [];
    List<Widget> otherList = [];
    List<Widget> playlistsList = [];

    for (dynamic item in searchResScrController.resultContent.entries) {
      final keyLower = item.key.toLowerCase();
      if (keyLower == "songs" || keyLower == "videos") {
        final w = SeparateTabItemWidget(
          items: List<MediaItem>.from(item.value),
          title: item.key,
          isCompleteList: false,
        );
        if (keyLower == "songs") {
          songsList.add(w);
        } else {
          otherList.add(w);
        }
      } else if (keyLower == "albums") {
        otherList.add(ContentListWidget(
          content: AlbumContent(
              title: item.key, albumList: List<Album>.from(item.value)),
          isHomeContent: false,
        ));
      } 
      else if (item.key.toLowerCase().contains("playlist")) {
        playlistsList.add(
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              title: Text(item.key, style: Theme.of(context).textTheme.titleLarge),
              tilePadding: const EdgeInsets.symmetric(horizontal: 0),
              children: [
                ContentListWidget(
                  content: PlaylistContent(
                    title: item.key,
                    playlistList: List<Playlist>.from(item.value),
                  ),
                  isHomeContent: false,
                  hideTitle: true,
                )
              ],
            ),
          )
        );
      } 
      else if (keyLower.contains("artist")) {
        otherList.add(SeparateTabItemWidget(
          items: List<Artist>.from(item.value),
          title: item.key,
          isCompleteList: false,
        ));
      }
    }

    return [...songsList, ...otherList, ...playlistsList];
  }
}
