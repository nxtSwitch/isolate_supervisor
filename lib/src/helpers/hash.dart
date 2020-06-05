/// Jenkins hash functions
/// https://en.wikipedia.org/wiki/Jenkins_hash_function
int hash(Iterable objects) 
{
  assert(objects != null);
  return _finish(objects?.fold(0, _combine) ?? 0);
}

int _combine(int hash, dynamic object) 
{
  hash = 0x1fffffff & (hash + object.hashCode);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int _finish(int hash) 
{
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}