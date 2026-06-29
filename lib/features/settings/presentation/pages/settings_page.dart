import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目设置', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.account_circle_outlined),
            title: Text('私人助理档案'),
            trailing: Icon(Icons.chevron_right),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('本地数据库管理'),
            subtitle: Text('基于 Drift 的本地存储数据流控制'),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.key),
            title: Text('API Keys / 模型配置'),
            subtitle: Text('本地 Ollama / 线上大模型对接'),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('主题与外观'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
