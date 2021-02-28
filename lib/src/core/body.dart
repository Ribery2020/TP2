
import 'dart:math' show Point;

const zeroPoint = Point<double>(0, 0);

const _epsilon = 0.0001;


class Body {
  Point<double> _velocity;
  Point<double> _location;

  Point<double> get velocity => _velocity;

  Point<double> get location => _location;

  Body({Point<double> location = zeroPoint, Point<double> velocity = zeroPoint})
      : assert(location.magnitude.isFinite),
        _location = location,
        assert(velocity.magnitude.isFinite),
        _velocity = velocity;

  factory Body.raw(double x, double y, double vx, double vy) =>
      Body(location: Point(x, y), velocity: Point(vx, vy));

  Body clone() => Body(location: _location, velocity: _velocity);

  
  void kick(Point<double> delta) {
    assert(delta.magnitude.isFinite);
    _velocity = delta;
  }

 
  bool animate(double seconds,
      {Point<double> force = zeroPoint,
      double drag = 0,
      double maxVelocity,
      Point<double> snapTo}) {
    assert(seconds.isFinite && seconds > 0,
        'milliseconds must be finite and > 0 (was $seconds)');

    force ??= zeroPoint;
    assert(force.x.isFinite && force.y.isFinite, 'force must be finite');

    drag ??= 0;
    assert(drag.isFinite && drag >= 0, 'drag must be finiate and >= 0');

    maxVelocity ??= double.infinity;
    assert(maxVelocity > 0, 'maxVelocity must be null or > 0');

    final dragVelocity = _velocity * (1 - drag * seconds);

    if (_sameDirection(_velocity, dragVelocity)) {
      assert(dragVelocity.magnitude <= _velocity.magnitude,
          'Huh? $dragVelocity $_velocity');
      _velocity = dragVelocity;
    } else {
      _velocity = zeroPoint;
    }

    
    _velocity += force * seconds;

  
    if (_velocity.magnitude > maxVelocity) {
      _velocity = _unitPoint(_velocity) * maxVelocity;
    }

  
    final locationDelta = _velocity * seconds;
    if (locationDelta.magnitude > _epsilon ||
        (force.magnitude * seconds) > _epsilon) {
      _location += locationDelta;
      return true;
    } else {
      if (snapTo != null && (_location.distanceTo(snapTo) < _epsilon * 2)) {
        _location = snapTo;
      }
      _velocity = zeroPoint;
      return false;
    }
  }

  @override
  String toString() =>
      'Body @(${_location.x},${_location.y}) ↕(${_velocity.x},${_velocity.y})';

  @override
  bool operator ==(Object other) =>
      other is Body &&
      other._location == _location &&
      other._velocity == _velocity;


  @override
  int get hashCode => 199;
}

Point<double> _unitPoint(Point<double> source) {
  final result = source * (1 / source.magnitude);
  return Point(result.x.isNaN ? 0 : result.x, result.y.isNaN ? 0 : result.y);
}

bool _sameDirection(Point a, Point b) {
  return a.x.sign == b.x.sign && a.y.sign == b.y.sign;
}
