import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'date_picker_theme.dart';
import 'date_picker_constants.dart';
import 'i18n/date_picker_i18n.dart';
import 'widget/date_picker_widget.dart';

enum DateTimePickerMode {
  /// Display DatePicker
  date,

  /// Display DateTimePicker
  datetime,
}

class DatePicker {
  /// Display date picker in bottom sheet.
  ///
  /// context: [BuildContext]
  /// minDateTime: [DateTime] minimum date time
  /// maxDateTime: [DateTime] maximum date time
  /// initialDateTime: [DateTime] initial date time for selected
  /// dateFormat: [String] date format pattern
  /// locale: [DateTimePickerLocale] internationalization
  /// pickerMode: [DateTimePickerMode] display mode: date(DatePicker)、time(TimePicker)、datetime(DateTimePicker)
  /// pickerTheme: [DateTimePickerTheme] the theme of date time picker
  /// onCancel: [DateVoidCallback] pressed title cancel widget event
  /// onClose: [DateVoidCallback] date picker closed event
  /// onChange: [DateValueCallback] selected date time changed event
  /// onConfirm: [DateValueCallback] pressed title confirm widget event
  static Future<DateTime> showSimpleDatePicker(
    BuildContext context, {
    DateTime minDateTime,
    DateTime maxDateTime,
    DateTime initialDateTime,
    String dateFormat,
    DateTimePickerLocale locale: DATETIME_PICKER_LOCALE_DEFAULT,
    DateTimePickerMode pickerMode: DateTimePickerMode.date,
    Color backgroundColor,
    TextStyle itemTextStyle,
    String titleText,
    String confirmText,
    String cancelText,
  }) {
    DateTime _selectedDate = initialDateTime;

    // handle the range of datetime
    if (minDateTime == null) {
      minDateTime = DateTime.parse(DATE_PICKER_MIN_DATETIME);
    }
    if (maxDateTime == null) {
      maxDateTime = DateTime.parse(DATE_PICKER_MAX_DATETIME);
    }

    // handle initial DateTime
    if (initialDateTime == null) {
      initialDateTime = DateTime.now();
    }

    if (backgroundColor == null)
      backgroundColor = DateTimePickerTheme.Default.backgroundColor;
    if (itemTextStyle == null)
      itemTextStyle = DateTimePickerTheme.Default.itemTextStyle;

    var datePickerDialog = AlertDialog(
      title: Text(
        titleText ?? "Select Date",
        style: TextStyle(color: itemTextStyle.color),
      ),
      backgroundColor: backgroundColor,
      content: Container(
        child: DatePickerWidget(
          minDateTime: minDateTime,
          maxDateTime: maxDateTime,
          initialDateTime: initialDateTime,
          dateFormat: dateFormat,
          locale: locale,
          pickerTheme: DateTimePickerTheme(
            backgroundColor: backgroundColor,
            itemTextStyle: itemTextStyle,
          ),
          onChange: ((DateTime date, list) {
            _selectedDate = date;
          }),
        ),
      ),
      actions: <Widget>[
        FlatButton(
          textColor: itemTextStyle.color,
          child: Text(confirmText ?? "OK"),
          onPressed: () {
            Navigator.pop(context, _selectedDate);
          },
        ),
        FlatButton(
          textColor: itemTextStyle.color,
          child: Text(cancelText ?? "Cancel"),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ],
    );
    return showDialog(
        useRootNavigator: false,
        context: context,
        builder: (context) => datePickerDialog);
  }
}

class _DatePickerRoute<T> extends PopupRoute<T> {
  _DatePickerRoute({
    this.minDateTime,
    this.maxDateTime,
    this.initialDateTime,
    this.dateFormat,
    this.locale,
    this.pickerMode,
    this.pickerTheme,
    this.onCancel,
    this.onChange,
    this.onConfirm,
    this.theme,
    this.barrierLabel,
    RouteSettings settings,
  }) : super(settings: settings);

  final DateTime minDateTime, maxDateTime, initialDateTime;
  final String dateFormat;
  final DateTimePickerLocale locale;
  final DateTimePickerMode pickerMode;
  final DateTimePickerTheme pickerTheme;
  final VoidCallback onCancel;
  final DateValueCallback onChange;
  final DateValueCallback onConfirm;

  final ThemeData theme;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get barrierDismissible => true;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => Colors.black54;

  AnimationController _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController =
        BottomSheet.createAnimationController(navigator.overlay);
    return _animationController;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    double height = pickerTheme.pickerHeight;
    if (pickerTheme.title != null || pickerTheme.showTitle) {
      height += pickerTheme.titleHeight;
    }

    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: _DatePickerComponent(route: this, pickerHeight: height),
    );

    if (theme != null) {
      bottomSheet = Theme(data: theme, child: bottomSheet);
    }
    return bottomSheet;
  }
}

class _DatePickerComponent extends StatelessWidget {
  final _DatePickerRoute route;
  final double _pickerHeight;

  _DatePickerComponent({Key key, @required this.route, @required pickerHeight})
      : this._pickerHeight = pickerHeight;

  @override
  Widget build(BuildContext context) {
    Widget pickerWidget = DatePickerWidget(
      minDateTime: route.minDateTime,
      maxDateTime: route.maxDateTime,
      initialDateTime: route.initialDateTime,
      dateFormat: route.dateFormat,
      locale: route.locale,
      pickerTheme: route.pickerTheme,
      onCancel: route.onCancel,
      onChange: route.onChange,
      onConfirm: route.onConfirm,
    );
    return GestureDetector(
      child: AnimatedBuilder(
        animation: route.animation,
        builder: (BuildContext context, Widget child) {
          return ClipRect(
            child: CustomSingleChildLayout(
              delegate: _BottomPickerLayout(route.animation.value,
                  contentHeight: _pickerHeight),
              child: pickerWidget,
            ),
          );
        },
      ),
    );
  }
}

class _BottomPickerLayout extends SingleChildLayoutDelegate {
  _BottomPickerLayout(this.progress, {this.contentHeight});

  final double progress;
  final double contentHeight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: contentHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double height = size.height - childSize.height * progress;
    return Offset(0.0, height);
  }

  @override
  bool shouldRelayout(_BottomPickerLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}