import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Pôster na proporção 2:3. Sem URL, ou se a imagem falhar, mostra um
/// cartaz neutro com a claquete e o título — nunca uma imagem inventada.
class MoviePoster extends StatelessWidget {
  const MoviePoster({
    super.key,
    required this.url,
    required this.title,
    this.width = 72,
    this.radius = AppRadius.s,
  });

  final String? url;
  final String title;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.5;
    final placeholder = _PosterPlaceholder(title: title, width: width);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Semantics(
      image: true,
      label: url == null ? null : 'Pôster de $title',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: width,
          height: height,
          child: url == null
              ? placeholder
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  // Decodifica no tamanho exibido para economizar memória.
                  cacheWidth: (width * dpr).round(),
                  // Na Web, servidores sem CORS ainda exibem a imagem via <img>.
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => placeholder,
                  frameBuilder: (context, child, frame, wasSync) {
                    if (wasSync || frame != null) return child;
                    return ColoredBox(color: AppColors.beigeDeep, child: child);
                  },
                ),
        ),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.title, required this.width});

  final String title;
  final double width;

  @override
  Widget build(BuildContext context) {
    final showTitle = width >= 90;
    return ColoredBox(
      color: AppColors.beigeDeep,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: showTitle ? const Alignment(0, -0.35) : Alignment.center,
            child: Icon(
              Icons.movie_creation_outlined,
              size: width * 0.36,
              color: AppColors.warmGray,
            ),
          ),
          if (showTitle)
            Align(
              alignment: const Alignment(0, 0.6),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.1),
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: AppColors.warmGrayText,
                    fontSize: (width * 0.09).clamp(10, 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
