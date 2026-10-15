import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

const String kPostsUrl = 'https://jsonplaceholder.typicode.com/posts';
const String kBoxName = 'favoritesBox';

/// Set to false to show only the fetched API text on the tiles.
const bool kUseCuratedContent = true;

const Color kIgBlue = Color(0xFF0095F6);
const Color kIgRed = Color(0xFFED4956);
const Color kIgText = Color(0xFF262626);
const Color kIgGrey = Color(0xFF8E8E8E);
const Color kIgBorder = Color(0xFFDBDBDB);
const Color kIgHashtag = Color(0xFF00376B);

const LinearGradient kIgGradient = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [
    Color(0xFFFCAF45),
    Color(0xFFF77737),
    Color(0xFFFD1D1D),
    Color(0xFFC13584),
    Color(0xFF833AB4),
  ],
);

const List<String> kCategories = [
  'Motivation',
  'Jokes',
  'News',
  'Facts',
  'Tips'
];

const Map<String, List<Color>> kCategoryColors = {
  'All': [Color(0xFF0095F6), Color(0xFF833AB4)],
  'Motivation': [Color(0xFF833AB4), Color(0xFFFD1D1D)],
  'Jokes': [Color(0xFFE1306C), Color(0xFFF77737)],
  'News': [Color(0xFF1C3D5A), Color(0xFF2C7DA0)],
  'Facts': [Color(0xFF0F766E), Color(0xFF14B8A6)],
  'Tips': [Color(0xFF5B21B6), Color(0xFF3B82F6)],
  'My Post': [Color(0xFF262626), Color(0xFF595959)],
};

const Map<String, IconData> kCategoryIcons = {
  'All': Icons.dynamic_feed,
  'Motivation': Icons.bolt,
  'Jokes': Icons.emoji_emotions,
  'News': Icons.newspaper,
  'Facts': Icons.lightbulb,
  'Tips': Icons.tips_and_updates,
  'My Post': Icons.person,
};

const Map<String, String> kCategoryHandles = {
  'Motivation': 'daily.motivation',
  'Jokes': 'dev.jokes',
  'News': 'throwback.news',
  'Facts': 'did.you.know',
  'Tips': 'study.tips',
  'My Post': 'you',
};

List<Color> colorsFor(String category) =>
    kCategoryColors[category] ?? kCategoryColors['My Post']!;
IconData iconFor(String category) => kCategoryIcons[category] ?? Icons.article;
String handleFor(String category) =>
    kCategoryHandles[category] ?? 'post.reader';

class PostContent {
  final String category;
  final String headline;
  final String text;
  const PostContent(this.category, this.headline, this.text);
}

const List<PostContent> kContent = [
  PostContent('Motivation', 'Start before you feel ready',
      "It always seems impossible until it's done. - Nelson Mandela"),
  PostContent('Jokes', 'Dark mode',
      'Why do programmers prefer dark mode? Because light attracts bugs.'),
  PostContent('News', 'Webb telescope debuts',
      'In July 2022, NASA shared the first full-color images from the James Webb Space Telescope, showing galaxies billions of light-years away.'),
  PostContent('Facts', 'Honey never spoils',
      'Jars of honey found in ancient Egyptian tombs were still edible after thousands of years.'),
  PostContent('Tips', 'Focus blocks',
      'Study for 25 minutes, then take a 5-minute break. Repeat four times, then rest a little longer.'),
  PostContent('Motivation', 'Small steps count',
      'Do what you can, with what you have, where you are. - Theodore Roosevelt'),
  PostContent('Jokes', 'Wi-Fi talk',
      'I told my Wi-Fi we needed to talk. Now we have a stronger connection.'),
  PostContent('News', 'Perseverance lands on Mars',
      "In February 2021, NASA's Perseverance rover touched down on Mars to search for signs of ancient life."),
  PostContent(
      'Facts', 'Octopus power', 'An octopus has three hearts and blue blood.'),
  PostContent('Tips', 'Hydrate first',
      'Drink a glass of water before you start studying. Small habits keep you alert.'),
  PostContent('Motivation', 'Love the work',
      'The only way to do great work is to love what you do. - Steve Jobs'),
  PostContent('Jokes', 'Binary',
      "There are 10 types of people: those who understand binary and those who don't."),
  PostContent('News', 'Artemis I comes home',
      "In December 2022, NASA's Orion capsule splashed down after an uncrewed trip around the Moon on the Artemis I mission."),
  PostContent('Facts', 'Berry confusing',
      'Botanically speaking, bananas are berries, but strawberries are not.'),
  PostContent('Tips', 'Commit often',
      'Commit small and often. Future you will be thankful when something breaks.'),
  PostContent('Motivation', 'Fall down, get up',
      'Fall seven times, stand up eight. - Japanese proverb'),
  PostContent('Jokes', 'Surprise features',
      'My code has no bugs. It just has surprise features.'),
  PostContent('News', 'The web goes public',
      "In 1991, Tim Berners-Lee's World Wide Web opened to the public and changed how the world shares information."),
  PostContent('Facts', 'Island nation',
      'The Philippines is made up of more than 7,600 islands.'),
  PostContent('Tips', 'Sleep beats cramming',
      'A full night of sleep helps you remember more than a last-minute all-nighter.'),
  PostContent('Motivation', 'Take the shot',
      "You miss 100% of the shots you don't take. - Wayne Gretzky"),
  PostContent('Jokes', 'Widget tree',
      'Why did the Flutter dev bring a ladder to work? To reach the top of the widget tree.'),
  PostContent('News', 'Chandrayaan-3 makes history',
      "In August 2023, India's Chandrayaan-3 landed near the Moon's south pole, a first for any country."),
  PostContent('Facts', 'Hot stuff',
      "A bolt of lightning is about five times hotter than the surface of the Sun."),
  PostContent('Tips', 'Teach it back',
      'Explain a topic in your own words. If you can teach it, you understand it.'),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(kBoxName);
  runApp(const PostReaderApp());
}

class Post {
  final int id;
  final String title;
  final String body;
  final String category;

  /// Decorative text for the gradient tile (empty = show the body instead)
  final String featured;

  const Post({
    required this.id,
    required this.title,
    required this.body,
    this.category = 'Posts',
    this.featured = '',
  });

  /// title and body always come from the API response
  factory Post.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final title = (json['title'] ?? '') as String;
    final body = (json['body'] ?? '') as String;
    if (kUseCuratedContent) {
      final c = kContent[(id - 1) % kContent.length];
      // The API text is Latin placeholder, so use the English curated
      // headline/text for what is displayed.
      return Post(
        id: id,
        title: c.headline,
        body: c.text,
        category: c.category,
        featured: c.text,
      );
    }
    return Post(id: id, title: title, body: body);
  }

  /// Arguments passed to the details screen via Navigator.pushNamed
  Map<String, dynamic> toArguments() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'featured': featured,
      };

  /// What gets stored in Hive
  Map<String, dynamic> toMap() => {...toArguments(), 'note': ''};
}

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

void showAppMessage(BuildContext context, String message,
    {bool isError = false, SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        action: action,
        backgroundColor: isError ? kIgRed : kIgText,
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// Like / unlike (Hive put / delete, with undo).
void toggleFavorite(BuildContext context, Post post) {
  final box = Hive.box(kBoxName);

  if (box.containsKey(post.id)) {
    final removed = Map<String, dynamic>.from(box.get(post.id) as Map);
    box.delete(post.id);
    showAppMessage(
      context,
      'Removed from Favorites',
      action: SnackBarAction(
        label: 'Undo',
        textColor: kIgBlue,
        onPressed: () => box.put(post.id, removed),
      ),
    );
  } else {
    box.put(post.id, post.toMap());
    showAppMessage(context, 'Saved to Favorites');
  }
}

const PreferredSize kAppBarDivider = PreferredSize(
  preferredSize: Size.fromHeight(1),
  child: Divider(height: 1, thickness: 1, color: kIgBorder),
);

class PostReaderApp extends StatelessWidget {
  const PostReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: kIgBlue,
        onPrimary: Colors.white,
        error: kIgRed,
        surface: Colors.white,
        onSurface: kIgText,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: kIgText),
        titleMedium: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: kIgText),
        bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: kIgText),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: kIgText),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: kIgText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: kIgText,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kIgBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kIgGrey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kIgRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kIgRed),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kIgBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFEFEFEF),
          disabledForegroundColor: kIgGrey,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kIgBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    return MaterialApp(
      title: 'Post Reader & Favorites',
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 560;
            return ColoredBox(
              color: const Color(0xFFF2F2F2),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: isWide
                          ? const Border.symmetric(
                              vertical: BorderSide(color: kIgBorder),
                            )
                          : null,
                    ),
                    child: ClipRect(child: child),
                  ),
                ),
              ),
            );
          },
        );
      },
      // Part 1: three named routes
      initialRoute: '/',
      routes: {
        '/': (context) => const PostsScreen(),
        '/details': (context) => const PostDetailsScreen(),
        '/favorites': (context) => const FavoritesScreen(),
      },
    );
  }
}

/// Circle avatar with the gradient "story" ring.
class RingAvatar extends StatelessWidget {
  final String category;
  final double size;
  final bool ring;

  const RingAvatar({
    super.key,
    required this.category,
    this.size = 40,
    this.ring = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring ? kIgGradient : null,
        color: ring ? null : kIgBorder,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: colorsFor(category)),
          ),
          child: Center(
            child:
                Icon(iconFor(category), color: Colors.white, size: size * 0.42),
          ),
        ),
      ),
    );
  }
}

/// ListTile at the top of each post: avatar, fetched title, handle + category.
class PostHeader extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const PostHeader({super.key, required this.post, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      leading: RingAvatar(category: post.category, size: 44),
      title: Text(
        capitalize(post.title),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${handleFor(post.category)} \u2022 ${post.category}',
        style: const TextStyle(fontSize: 12, color: kIgGrey),
      ),
      trailing: onDelete == null
          ? const Icon(Icons.more_horiz, color: kIgText)
          : PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_horiz, color: kIgText),
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onSelected: (value) {
                if (value == 'delete') onDelete!();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: kIgRed),
                      SizedBox(width: 12),
                      Text('Delete post',
                          style: TextStyle(
                              color: kIgRed, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// The big gradient "photo" that holds the quote / joke / news text.
class PostTile extends StatelessWidget {
  final Post post;
  final double heightFactor;

  const PostTile({super.key, required this.post, this.heightFactor = 0.8});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final height = (width * heightFactor).clamp(220.0, 560.0);
        final fontSize = (width / 18).clamp(16.0, 24.0);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colorsFor(post.category),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  iconFor(post.category),
                  size: (width * 0.3).clamp(100.0, 170.0),
                  color: Colors.white.withAlpha(35),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (width * 0.07).clamp(16.0, 36.0),
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: height - 64),
                  child: Center(
                    child: Text(
                      capitalize(
                          post.featured.isNotEmpty ? post.featured : post.body),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Heart button that reflects (and creates) the favorite state in Hive.
class HeartButton extends StatelessWidget {
  final Post post;
  const HeartButton({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(kBoxName);
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: [post.id]),
      builder: (context, Box b, _) {
        final saved = b.containsKey(post.id);
        return IconButton(
          tooltip: saved ? 'Unlike' : 'Like',
          icon: Icon(
            saved ? Icons.favorite : Icons.favorite_border,
            color: saved ? kIgRed : kIgText,
            size: 28,
          ),
          onPressed: () => toggleFavorite(context, post),
        );
      },
    );
  }
}

/// "handle  body" caption with hashtags, like an Instagram caption.
class PostCaption extends StatelessWidget {
  final Post post;
  final int? maxLines;
  const PostCaption({super.key, required this.post, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final tag = post.category.toLowerCase().replaceAll(' ', '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${handleFor(post.category)}  ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: capitalize(post.body).replaceAll('\n', ' ')),
              ],
            ),
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, height: 1.4, color: kIgText),
          ),
          const SizedBox(height: 4),
          Text(
            '#$tag #post${post.id}',
            style: const TextStyle(fontSize: 14, color: kIgHashtag),
          ),
        ],
      ),
    );
  }
}

/// One post in the feed.
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onDelete;
  const PostCard({super.key, required this.post, this.onDelete});

  void _open(BuildContext context) {
    // Part 1: pass id, title, body as arguments
    Navigator.pushNamed(context, '/details', arguments: post.toArguments());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostHeader(
          post: post,
          onTap: () => _open(context),
          onDelete: onDelete,
        ),
        InkWell(onTap: () => _open(context), child: PostTile(post: post)),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
          child: Row(
            children: [
              HeartButton(post: post),
              CommentButton(post: post),
            ],
          ),
        ),
        InkWell(
          onTap: () => _open(context),
          child: PostCaption(post: post, maxLines: 2),
        ),
        const Divider(height: 1, color: kIgBorder),
      ],
    );
  }
}

/// English comments used in place of the API's Latin placeholder text.
const List<String> kCuratedComments = [
  'This made my day, thanks for sharing!',
  'Needed to hear this today.',
  'Love this one. Saving it for later.',
  'So true. Everyone should read this.',
  'Great post, keep them coming!',
  'I did not know that. Super interesting.',
  'Sending this to my friends right now.',
  'This is exactly what I was looking for.',
  'Such a good reminder. Thank you!',
  'Okay, this one is my favorite so far.',
  'Short, simple and spot on.',
  'I read this twice. Really well said.',
];

class Comment {
  final int id;
  final String author;
  final String body;

  const Comment({this.id = 0, required this.author, required this.body});

  factory Comment.fromJson(Map<String, dynamic> json) {
    final email = (json['email'] ?? '') as String;
    final name = (json['name'] ?? 'user') as String;
    final id = (json['id'] as int?) ?? 0;
    // The API body is Latin placeholder text, so use English when curated.
    final body = kUseCuratedContent
        ? kCuratedComments[id % kCuratedComments.length]
        : ((json['body'] ?? '') as String).replaceAll('\n', ' ');
    return Comment(
      id: id,
      author:
          (email.contains('@') ? email.split('@').first : name).toLowerCase(),
      body: body,
    );
  }
}

class CommentButton extends StatelessWidget {
  final Post post;
  const CommentButton({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Comments',
      icon: const Icon(Icons.chat_bubble_outline, size: 26),
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => CommentsSheet(post: post),
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final Post post;
  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await http.get(Uri.parse('$kPostsUrl/${widget.post.id}/comments'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _comments = data
              .map((item) => Comment.fromJson(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Could not load comments (status code ${response.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load comments. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _statusMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://jsonplaceholder.typicode.com/comments'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'postId': widget.post.id,
          'name': 'you',
          'email': 'you@postreader.app',
          'body': text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final created = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _comments.insert(
            0,
            Comment(
              id: (created['id'] as int?) ?? 0,
              author: 'you',
              body: text,
            ),
          );
          _controller.clear();
          _statusMessage = 'Comment posted';
          _statusIsError = false;
        });
      } else {
        setState(() {
          _statusMessage =
              'Failed to post comment (status ${response.statusCode}).';
          _statusIsError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to post comment. Check your connection.';
        _statusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<bool> _requestDelete(Comment comment) async {
    try {
      final response = await http.delete(
        Uri.parse(
            'https://jsonplaceholder.typicode.com/comments/${comment.id}'),
      );

      if (!mounted) return false;

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'Comment deleted';
          _statusIsError = false;
        });
        return true;
      }

      setState(() {
        _statusMessage =
            'Failed to delete comment (status ${response.statusCode}).';
        _statusIsError = true;
      });
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _statusMessage = 'Failed to delete comment. Check your connection.';
        _statusIsError = true;
      });
      return false;
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final deleted = await _requestDelete(comment);
    if (deleted && mounted) {
      setState(() => _comments.remove(comment));
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inset = media.viewInsets.bottom;
    final maxHeight = media.size.height - inset - 80;
    final sheetHeight = media.size.height * 0.75 < maxHeight
        ? media.size.height * 0.75
        : maxHeight;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kIgBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Comments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1, color: kIgBorder),
            Expanded(child: _buildList()),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _statusIsError ? kIgRed : kIgGrey,
                    ),
                  ),
                ),
              ),
            const Divider(height: 1, color: kIgBorder),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kIgGrey, strokeWidth: 2.5),
      );
    }

    if (_errorMessage != null) {
      return MessageView(
        icon: Icons.cloud_off,
        message: _errorMessage!,
        actionLabel: 'Try Again',
        onAction: _loadComments,
      );
    }

    if (_comments.isEmpty) {
      return const MessageView(
        icon: Icons.chat_bubble_outline,
        message: 'No comments yet.\nStart the conversation.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final c = _comments[index];
        final isMe = c.author == 'you';
        final row = Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isMe ? kIgBlue : const Color(0xFFEFEFEF),
                child: Text(
                  c.author.isEmpty ? '?' : c.author[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isMe ? Colors.white : kIgText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${c.author}  ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: capitalize(c.body)),
                    ],
                  ),
                  style: const TextStyle(
                      fontSize: 14, height: 1.4, color: kIgText),
                ),
              ),
              IconButton(
                tooltip: 'Delete comment',
                visualDensity: VisualDensity.compact,
                icon:
                    const Icon(Icons.delete_outline, size: 20, color: kIgGrey),
                onPressed: () => _deleteComment(c),
              ),
            ],
          ),
        );

        return Dismissible(
          key: ObjectKey(c),
          direction: DismissDirection.endToStart,
          background: Container(
            padding: const EdgeInsets.only(right: 24),
            alignment: Alignment.centerRight,
            color: kIgRed,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _requestDelete(c),
          onDismissed: (_) => setState(() => _comments.remove(c)),
          child: ColoredBox(color: Colors.white, child: row),
        );
      },
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: kIgBlue,
              child: Text('Y',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendComment(),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: kIgBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: kIgGrey),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: (_controller.text.trim().isEmpty || _isSending)
                  ? null
                  : _sendComment,
              child: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A story bubble that filters the feed by category.
class StoryBubble extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const StoryBubble({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            RingAvatar(category: label, size: 64, ring: selected),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: kIgText,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoriesBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const StoriesBar(
      {super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final items = ['All', ...kCategories];
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kIgBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final label in items)
              StoryBubble(
                label: label,
                selected: label == selected,
                onTap: () => onSelected(label),
              ),
          ],
        ),
      ),
    );
  }
}

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    fetchPosts(); // Part 2: GET called from initState()
  }

  Future<void> fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(kPostsUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final posts = data
            .map((item) => Post.fromJson(item as Map<String, dynamic>))
            .toList();
        if (!mounted) return;
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Could not load posts (status code ${response.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Something went wrong while loading posts.\nCheck your internet connection and try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreatePostDialog(),
    );
    if (result == null) return;
    await _sendPost(result['title']!, result['body']!);
  }

  Future<void> _sendPost(String title, String body) async {
    try {
      final response = await http.post(
        Uri.parse(kPostsUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        // JSONPlaceholder fakes the write and always returns id 101, so we
        // give the local post a unique id to avoid Hive key collisions.
        setState(() {
          _selectedCategory = 'All';
          _posts.insert(
            0,
            Post(
              // Hive int keys must be below 2^32, so keep the id in range
              // (and above the 1-100 range used by the API posts).
              id: 1000 + DateTime.now().millisecondsSinceEpoch % 1000000000,
              title: title,
              body: body,
              category: 'My Post',
            ),
          );
        });
        showAppMessage(context, 'Post shared successfully!');
      } else {
        showAppMessage(
            context, 'Failed to create post (status ${response.statusCode}).',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
          context, 'Failed to create post. Please check your connection.',
          isError: true);
    }
  }

  Future<void> _confirmDelete(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete post?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
          'This removes the post from the feed and from your Favorites.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: kIgGrey),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: kIgRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deletePost(post);
  }

  Future<void> _deletePost(Post post) async {
    try {
      final response = await http.delete(Uri.parse('$kPostsUrl/${post.id}'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Hive.box(kBoxName).delete(post.id);
        setState(() => _posts.removeWhere((p) => p.id == post.id));
        showAppMessage(context, 'Post deleted');
      } else {
        showAppMessage(
            context, 'Failed to delete post (status ${response.statusCode}).',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
          context, 'Failed to delete post. Please check your connection.',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ShaderMask(
            shaderCallback: (bounds) => kIgGradient.createShader(bounds),
            child: const Padding(
              // extra room on the right so the italic "r" is not clipped
              padding: EdgeInsets.only(right: 10),
              child: Text(
                'Post Reader',
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Favorites',
            icon: const Icon(Icons.favorite_border, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: kAppBarDivider,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        tooltip: 'New post',
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: Colors.transparent,
        shape: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: kIgGradient,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kIgGrey, strokeWidth: 2.5),
      );
    }

    if (_errorMessage != null) {
      return MessageView(
        icon: Icons.cloud_off,
        message: _errorMessage!,
        actionLabel: 'Try Again',
        onAction: fetchPosts,
      );
    }

    final visible = _selectedCategory == 'All'
        ? _posts
        : _posts.where((p) => p.category == _selectedCategory).toList();

    return RefreshIndicator(
      color: kIgText,
      onRefresh: fetchPosts,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: visible.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return kUseCuratedContent
                ? StoriesBar(
                    selected: _selectedCategory,
                    onSelected: (c) => setState(() => _selectedCategory = c),
                  )
                : const SizedBox.shrink();
          }
          final post = visible[index - 1];
          return PostCard(post: post, onDelete: () => _confirmDelete(post));
        },
      ),
    );
  }
}

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({super.key});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
      });
    }
  }

  String? _required(String? value, String field) =>
      (value == null || value.trim().isEmpty) ? '$field cannot be empty' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('New Post',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => _required(v, 'Title'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bodyController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Write a caption...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => _required(v, 'Body'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: kIgGrey),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Share')),
      ],
    );
  }
}

class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Part 1: retrieve arguments with ModalRoute
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final post = Post(
      id: args['id'] as int,
      title: args['title'] as String,
      body: args['body'] as String,
      category: (args['category'] as String?) ?? 'Posts',
      featured: (args['featured'] as String?) ?? '',
    );

    final box = Hive.box(kBoxName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        bottom: kAppBarDivider,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostHeader(post: post),
            PostTile(post: post, heightFactor: 1.0),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
              child: Row(
                children: [
                  HeartButton(post: post),
                  CommentButton(post: post),
                ],
              ),
            ),
            PostCaption(post: post),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              child: Text(
                'Post ID: ${post.id}',
                style: const TextStyle(fontSize: 12, color: kIgGrey),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: kIgBorder)),
          ),
          // Rebuilds automatically when the box changes
          child: ValueListenableBuilder(
            valueListenable: box.listenable(keys: [post.id]),
            builder: (context, Box b, _) {
              final alreadySaved = b.containsKey(post.id);
              return SizedBox(
                width: double.infinity,
                child: alreadySaved
                    ? OutlinedButton.icon(
                        onPressed: () => toggleFavorite(context, post),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kIgText,
                          side: const BorderSide(color: kIgBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon:
                            const Icon(Icons.favorite, color: kIgRed, size: 20),
                        label: const Text('Saved \u2022 Tap to remove'),
                      )
                    : FilledButton.icon(
                        onPressed: () => toggleFavorite(context, post),
                        icon: const Icon(Icons.favorite_border, size: 20),
                        label: const Text('Save to Favorites'),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _editNote(
      BuildContext context, Box box, Map<String, dynamic> fav) async {
    final controller =
        TextEditingController(text: fav['note'] as String? ?? '');

    final newNote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Personal Note',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 2,
          decoration: const InputDecoration(
            hintText: 'Add a comment...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: kIgGrey),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newNote == null) return;

    // Part 3 (Update): write the changed post back to the box
    box.put(fav['id'], {...fav, 'note': newNote});

    if (context.mounted) showAppMessage(context, 'Note updated');
  }

  void _delete(BuildContext context, Box box, int id) {
    // Part 3 (Delete)
    box.delete(id);
    showAppMessage(context, 'Removed from Favorites');
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(kBoxName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        bottom: kAppBarDivider,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          // Part 3 (Read): list everything saved using box.values
          final favorites =
              b.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();

          if (favorites.isEmpty) {
            return const MessageView(
              icon: Icons.favorite_border,
              message:
                  'No favorites yet.\nTap the heart on a post to save it here.',
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final fav = favorites[index];
              final int id = fav['id'] as int;
              final String category = (fav['category'] as String?) ?? 'Posts';
              final String note = (fav['note'] as String?) ?? '';

              return Dismissible(
                key: ValueKey(id),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.only(right: 24),
                  alignment: Alignment.centerRight,
                  color: kIgRed,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _delete(context, box, id),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/details',
                    arguments: {
                      'id': id,
                      'title': fav['title'],
                      'body': fav['body'],
                      'category': category,
                      'featured': fav['featured'] ?? '',
                    },
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: kIgBorder)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient:
                                LinearGradient(colors: colorsFor(category)),
                          ),
                          child: Icon(iconFor(category),
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                handleFor(category),
                                style: const TextStyle(
                                    fontSize: 12, color: kIgGrey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                capitalize(fav['title'] as String),
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                capitalize(fav['body'] as String)
                                    .replaceAll('\n', ' '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(fontSize: 13, height: 1.35),
                              ),
                              if (note.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFEFEF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'you  ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                        TextSpan(text: note),
                                      ],
                                    ),
                                    style: const TextStyle(
                                        fontSize: 13, color: kIgText),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              tooltip: 'Edit note',
                              icon: const Icon(Icons.edit_outlined, size: 22),
                              onPressed: () => _editNote(context, box, fav),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.delete_outline,
                                  size: 22, color: kIgRed),
                              onPressed: () => _delete(context, box, id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MessageView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kIgText, width: 2),
              ),
              child: Icon(icon, size: 44, color: kIgText),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.5, color: kIgText),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
