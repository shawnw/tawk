BEGIN {
   FS=OFS="\t"
}
{
   for (i=32; i<43; ++i)
      $0 = $0 OFS $i $(i+11)
}
1
