// Book cover: the image from the book, or a Koodo-style placeholder
// (a colored card with the title and author) when there is none.
import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/database.dart';

const List<Color> _placeholderColors = [
  Color(0xFF0179CA),
  Color(0xFF008F91),
  Color(0xFFF16464),
  Color(0xFF6867D1),
  Color(0xFFF97316),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFF0EA5E9),
  Color(0xFF64748B),
];

class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, this.decodeWidth = 300});

  final Book book;

  /// Width in pixels to decode the image at (keeps memory low in grids).
  final int decodeWidth;

  @override
  Widget build(BuildContext context) {
    final path = book.coverPath;
    final placeholder = _Placeholder(book: book);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: path == null
          ? placeholder
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              cacheWidth: decodeWidth,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final color = _placeholderColors[book.id.hashCode.abs() % _placeholderColors.length];
    return Container(
      color: color,
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, c) {
          final size = (c.maxWidth / 8).clamp(9.0, 18.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  book.title,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: size, fontWeight: FontWeight.w600, height: 1.15),
                ),
              ),
              if (book.authors.isNotEmpty)
                Text(
                  book.authors,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: size * 0.75),
                ),
            ],
          );
        },
      ),
    );
  }
}
