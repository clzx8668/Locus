import 'package:flutter/material.dart';

@immutable
class CrmColumnSchema {
  final String key;
  final String label;
  final double? width;
  final TextAlign textAlign;
  final bool sortable;

  const CrmColumnSchema({
    required this.key,
    required this.label,
    this.width,
    this.textAlign = TextAlign.left,
    this.sortable = false,
  });
}

const crmContactColumns = <CrmColumnSchema>[
  CrmColumnSchema(key: 'select', label: '', width: 26),
  CrmColumnSchema(key: 'contact', label: 'Contact', width: 240, sortable: true),
  CrmColumnSchema(key: 'company', label: 'Company', width: 180),
  CrmColumnSchema(key: 'phone', label: 'Phone', width: 140),
  CrmColumnSchema(key: 'email', label: 'Email'),
  CrmColumnSchema(
    key: 'updated',
    label: 'Updated',
    width: 90,
    textAlign: TextAlign.right,
    sortable: true,
  ),
];

const crmCompanyColumns = <CrmColumnSchema>[
  CrmColumnSchema(key: 'company', label: 'Company', width: 250, sortable: true),
  CrmColumnSchema(key: 'contacts', label: 'Contacts', width: 90),
  CrmColumnSchema(key: 'people', label: 'People'),
  CrmColumnSchema(
    key: 'updated',
    label: 'Updated',
    width: 100,
    textAlign: TextAlign.right,
    sortable: true,
  ),
];

const crmDealColumns = <CrmColumnSchema>[
  CrmColumnSchema(key: 'title', label: 'Deal', width: 220, sortable: true),
  CrmColumnSchema(key: 'company', label: 'Company', width: 170),
  CrmColumnSchema(key: 'contact', label: 'Contact', width: 150),
  CrmColumnSchema(key: 'stage', label: 'Stage', width: 120),
  CrmColumnSchema(
    key: 'value',
    label: 'Value',
    width: 110,
    textAlign: TextAlign.right,
  ),
  CrmColumnSchema(
    key: 'probability',
    label: 'Probability',
    width: 100,
    textAlign: TextAlign.right,
  ),
  CrmColumnSchema(
    key: 'close',
    label: 'Close',
    width: 90,
    textAlign: TextAlign.right,
    sortable: true,
  ),
];
