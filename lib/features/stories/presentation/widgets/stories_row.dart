import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/urls.dart';
import '../../../streams/presentation/widgets/streams_avatar_item.dart';
import '../cubit/stories_cubit.dart';
import '../pages/stories_viewer_page.dart';

/// Ряд кружков со сториз над лентой эфиров.
///
/// Раньше на этом месте стояла заглушка: ряд рисовался только когда идёт эфир,
/// в него подставлялся один синтетический элемент, а тап был пустым
/// колбэком — отсюда и «сториз не работают».
///
/// Виджет владеет и рядом, и отступом под ним, поэтому на пустой ленте с
/// экрана исчезает целиком, не оставляя дыры.
class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  /// Метрики один в один с прежним рядом, чтобы страница не поехала.
  static const double _height = 110;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoriesCubit, StoriesState>(
      builder: (context, state) {
        if (state.status == StoriesStatus.loading && state.groups.isEmpty) {
          return const _Skeleton(height: _height, gap: _gap);
        }
        // Пусто или ошибка — ничего не рисуем. Повтор делается pull-to-refresh,
        // а второй плейсхолдер поверх пустого состояния ленты дал бы два
        // «ничего нет» на одном экране.
        if (state.groups.isEmpty) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.groups.length,
                separatorBuilder: (_, __) => const SizedBox(width: 15),
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  final unviewed = state.groupHasUnviewed(group);
                  final avatar = group.seller.avatarUrl;
                  return StreamsAvatarItem(
                    imageUrl: (avatar != null && avatar.isNotEmpty)
                        ? '$imgUrl$avatar'
                        : '',
                    name: group.seller.displayName,
                    ringColor: unviewed
                        ? const Color(0xFF71CD32)
                        : Colors.white.withValues(alpha: 0.25),
                    onTap: () => openStoriesViewer(
                      context,
                      cubit: context.read<StoriesCubit>(),
                      initialGroupIndex: index,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: _gap),
          ],
        );
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height, required this.gap});
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: Shimmer.fromColors(
            // Не SimpleShimmerBlack из core/widgets: там и база, и подсветка
            // чёрные, а страница здесь тёмная — получилась бы чёрная дыра.
            baseColor: const Color(0xFF2A2A2A),
            highlightColor: const Color(0xFF3A3A3A),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 15),
              itemBuilder: (_, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(width: 48, height: 10, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: gap),
      ],
    );
  }
}
