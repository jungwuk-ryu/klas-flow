import 'dart:convert';

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
  SessionInfo? _session;
  List<CourseContext> _contexts = const <CourseContext>[];
  CourseContext? _currentContext;
  List<dynamic> _tasks = const <dynamic>[];

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
      _session = null;
      _contexts = const <CourseContext>[];
      _currentContext = null;
      _tasks = const <dynamic>[];
    });

    try {
      final bootstrap = await _client.loginAndBootstrap(id, password);
      final resolvedContext = _resolveCurrentContext(
        bootstrap.contexts,
        bootstrap.currentContext,
      );

      final tasks = await _client.endpoints.learning.taskStdList(
        payload: const {'currentPage': 0},
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _session = bootstrap.session;
        _contexts = List<CourseContext>.unmodifiable(bootstrap.contexts);
        _currentContext = resolvedContext;
        _tasks = List<dynamic>.unmodifiable(tasks);
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
    if (_session == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _client.endpoints.learning.taskStdList(
        payload: const {'currentPage': 0},
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _tasks = List<dynamic>.unmodifiable(tasks);
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

  Future<void> _changeContext(CourseContext? context) async {
    if (context == null || _session == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _client.setContext(
        selectYearhakgi: context.selectYearhakgi,
        selectSubj: context.selectSubj,
        selectChangeYn: context.selectChangeYn,
      );

      final tasks = await _client.endpoints.learning.taskStdList(
        payload: const {'currentPage': 0},
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentContext = context;
        _tasks = List<dynamic>.unmodifiable(tasks);
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
        _errorMessage = 'Failed to switch context.';
        _isLoading = false;
      });
    }
  }

  CourseContext? _resolveCurrentContext(
    List<CourseContext> contexts,
    CourseContext? currentContext,
  ) {
    if (contexts.isEmpty) {
      return null;
    }
    if (currentContext == null) {
      return contexts.first;
    }

    for (final context in contexts) {
      if (context.selectYearhakgi == currentContext.selectYearhakgi &&
          context.selectSubj == currentContext.selectSubj &&
          context.selectChangeYn == currentContext.selectChangeYn) {
        return context;
      }
    }

    return contexts.first;
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

  String _displayValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '(unknown)';
    }
    return value;
  }

  String _contextLabel(CourseContext context) {
    final name = context.subjectName?.trim();
    if (name != null && name.isNotEmpty) {
      return '$name (${context.selectYearhakgi}/${context.selectSubj})';
    }
    return '${context.selectYearhakgi}/${context.selectSubj}';
  }

  String _taskTitle(dynamic task) {
    if (task is Map) {
      const titleKeys = <String>[
        'taskTitle',
        'title',
        'subjectName',
        'subjNm',
        'contentsTitle',
      ];
      for (final key in titleKeys) {
        final value = task[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return _truncate(_stringify(task), 100);
    }
    return _truncate(task.toString(), 100);
  }

  String _taskSubtitle(dynamic task) {
    if (task is! Map) {
      return '';
    }

    const subtitleKeys = <String>[
      'deadline',
      'dueDate',
      'endDate',
      'submitEndDt',
      'subjectName',
      'subjNm',
    ];
    final fields = <String>[];
    for (final key in subtitleKeys) {
      final value = task[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isEmpty) {
        continue;
      }
      fields.add('$key: $text');
      if (fields.length == 2) {
        break;
      }
    }
    if (fields.isEmpty) {
      return '';
    }
    return fields.join('  |  ');
  }

  String _stringify(Object value) {
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength - 3)}...';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('klasflow Flutter Demo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (_isLikelyBrowserCrossOriginLogin) ...<Widget>[
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Web demo on ${Uri.base.origin} cannot keep KLAS session '
                    'cookies for ${_apiBaseUri.origin}. '
                    'Login will fail at LoginCaptcha/LoginConfirm. '
                    'Use Android/iOS/desktop, or a same-origin reverse proxy.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
            if (_session != null) ...<Widget>[
              const SizedBox(height: 16),
              _buildSessionCard(context),
              const SizedBox(height: 12),
              _buildContextCard(context),
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
              textInputAction: TextInputAction.next,
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

  Widget _buildSessionCard(BuildContext context) {
    final session = _session;
    if (session == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Session', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Authenticated: ${session.authenticated}'),
            Text('User ID: ${_displayValue(session.userId)}'),
            Text('User Name: ${_displayValue(session.userName)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildContextCard(BuildContext context) {
    final contexts = _contexts;
    final current = _resolveCurrentContext(contexts, _currentContext);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Contexts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Available contexts: ${contexts.length}'),
            const SizedBox(height: 8),
            if (contexts.isEmpty)
              const Text('No course context available.')
            else
              DropdownButtonFormField<CourseContext>(
                initialValue: current,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Current context',
                ),
                items: contexts
                    .map(
                      (context) => DropdownMenuItem<CourseContext>(
                        value: context,
                        child: Text(
                          _contextLabel(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isLoading ? null : _changeContext,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context) {
    final tasks = _tasks;

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
            Text('Loaded items: ${tasks.length}'),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              const Text('No task data available.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final task = tasks[index];
                  final subtitle = _taskSubtitle(task);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _taskTitle(task),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: subtitle.isEmpty
                        ? null
                        : Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
