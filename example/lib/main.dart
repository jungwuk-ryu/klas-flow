import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

void main() {
  runApp(const KlasflowDemoApp());
}

class KlasflowDemoApp extends StatelessWidget {
  const KlasflowDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'klasflow Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const KlasflowDemoPage(),
    );
  }
}

class KlasflowDemoPage extends StatefulWidget {
  const KlasflowDemoPage({super.key});

  @override
  State<KlasflowDemoPage> createState() => _KlasflowDemoPageState();
}

class _KlasflowDemoPageState extends State<KlasflowDemoPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final Uri _apiBaseUri;
  late final KlasClientConfig _clientConfig;
  late final KlasClient _client;

  bool _isLoading = false;
  String? _errorMessage;
  KlasUser? _user;
  KlasUserProfile? _profile;
  List<KlasCourse> _courses = const <KlasCourse>[];
  KlasCourse? _currentCourse;
  List<KlasTask> _tasks = const <KlasTask>[];

  @override
  void initState() {
    super.initState();
    _apiBaseUri = _resolveBaseUri();
    _clientConfig = KlasClientConfig(baseUri: _apiBaseUri);
    _client = KlasClient(config: _clientConfig);
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _loginAndLoad() async {
    if (_isLikelyBrowserCrossOriginLogin) {
      setState(() {
        _errorMessage =
            'Web cross-origin login is blocked by browser cookie policy. '
            'Use Android/iOS/desktop, or a same-origin reverse proxy.';
      });
      return;
    }

    final id = _idController.text.trim();
    final password = _passwordController.text;
    if (id.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter both ID and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _user = null;
      _profile = null;
      _courses = const <KlasCourse>[];
      _currentCourse = null;
      _tasks = const <KlasTask>[];
    });

    try {
      final user = await _client.login(id, password);
      final profile = await user.profile(refresh: true);
      final courses = await user.courses(refresh: true);
      final current = await user.defaultCourse();
      final tasks = current == null
          ? const <KlasTask>[]
          : await current.listTasks(page: 0);

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _profile = profile;
        _courses = List<KlasCourse>.unmodifiable(courses);
        _currentCourse = current;
        _tasks = List<KlasTask>.unmodifiable(tasks);
        _isLoading = false;
      });
    } on KlasException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _friendlyError(error);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadTasks() async {
    final course = _currentCourse;
    if (course == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await course.listTasks(page: 0);
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = List<KlasTask>.unmodifiable(tasks);
        _isLoading = false;
      });
    } on KlasException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _friendlyError(error);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Failed to load tasks.';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeCourse(KlasCourse? course) async {
    if (course == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await course.listTasks(page: 0);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentCourse = course;
        _tasks = List<KlasTask>.unmodifiable(tasks);
        _isLoading = false;
      });
    } on KlasException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _friendlyError(error);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Failed to switch course.';
        _isLoading = false;
      });
    }
  }

  String _friendlyError(KlasException error) {
    if (error is InvalidCredentialsException) {
      return 'Invalid credentials. Check your ID and password.';
    }
    if (error is OtpRequiredException) {
      return 'OTP verification is required for this account.';
    }
    if (error is CaptchaRequiredException) {
      return 'Captcha verification is required for this account.';
    }
    if (error is SessionExpiredException) {
      return 'Session expired. Please sign in again.';
    }
    if (error is NetworkException) {
      return 'Network request failed. Check your connection.';
    }
    if (error is ServiceUnavailableException) {
      return 'KLAS service is unavailable. Try again later.';
    }
    return 'KLAS request failed: ${error.message}';
  }

  bool get _isLikelyBrowserCrossOriginLogin {
    if (!kIsWeb) {
      return false;
    }
    final appOrigin = Uri.base;
    final apiOrigin = _clientConfig.baseUri;
    return appOrigin.scheme != apiOrigin.scheme ||
        appOrigin.host != apiOrigin.host ||
        _effectivePort(appOrigin) != _effectivePort(apiOrigin);
  }

  int _effectivePort(Uri uri) {
    if (uri.hasPort && uri.port != 0) {
      return uri.port;
    }
    return switch (uri.scheme) {
      'https' => 443,
      'http' => 80,
      _ => 0,
    };
  }

  Uri _resolveBaseUri() {
    const override = String.fromEnvironment('KLAS_BASE_URI');
    if (override.isEmpty) {
      return Uri(scheme: 'https', host: 'klas.kw.ac.kr');
    }
    final parsed = Uri.tryParse(override);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return Uri(scheme: 'https', host: 'klas.kw.ac.kr');
    }
    return parsed;
  }

  String _courseLabel(KlasCourse course) {
    final title = course.title ?? '(unknown course)';
    final professor = course.professorName;
    if (professor == null || professor.isEmpty) {
      return '$title [${course.termId}]';
    }
    return '$title - $professor [${course.termId}]';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('klasflow Flutter Demo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildLoginCard(context),
            if (_isLoading) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_user != null) ...<Widget>[
              const SizedBox(height: 16),
              _buildProfileCard(context),
              const SizedBox(height: 12),
              _buildCourseCard(context),
              const SizedBox(height: 12),
              _buildTaskCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Login', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _idController,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Student ID',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: true,
              onSubmitted: (_) {
                if (!_isLoading) {
                  _loginAndLoad();
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (_isLoading || _isLikelyBrowserCrossOriginLogin)
                  ? null
                  : _loginAndLoad,
              child: const Text('Sign in and load data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Profile', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Authenticated: ${profile.authenticated}'),
            Text('User ID: ${profile.userId ?? '(unknown)'}'),
            Text('User Name: ${profile.userName ?? '(unknown)'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Courses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Available courses: ${_courses.length}'),
            const SizedBox(height: 8),
            if (_courses.isEmpty)
              const Text('No course context available.')
            else
              DropdownButtonFormField<KlasCourse>(
                initialValue: _currentCourse,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Current course',
                ),
                items: _courses
                    .map(
                      (course) => DropdownMenuItem<KlasCourse>(
                        value: course,
                        child: Text(
                          _courseLabel(course),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isLoading ? null : _changeCourse,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Tasks', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: _isLoading ? null : _reloadTasks,
                  child: const Text('Reload'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Loaded items: ${_tasks.length}'),
            const SizedBox(height: 8),
            if (_tasks.isEmpty)
              const Text('No task data available.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final task = _tasks[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(task.title ?? '(untitled task)'),
                    subtitle: Text(
                      'No:${task.taskNo ?? '-'}  '
                      'Start:${task.startDate ?? '-'}  '
                      'Due:${task.expireDate ?? '-'}',
                    ),
                    trailing: Text(task.submitted == true ? 'Submitted' : '-'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
