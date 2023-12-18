def has_duplicates(arr):
    print(len(set(arr)))
    print(arr)
    return len(arr) != len(set(arr))
class Solution:
    def wordPattern(self, pattern: str, s: str) -> bool:
        dic = {}
        arrstr = s.split(" ")
        if len(arrstr) != len(pattern):
            return False
        for i in range(len(pattern)):
            if dic.get(pattern[i]) is not None:
                if not arrstr[i] == dic[pattern[i]]:
                    return False
            else:
                print(arrstr[i])
                dic[pattern[i]] = arrstr[i]
        # print(arrstr)
        diclist = list(dic.values())
        return not has_duplicates(diclist)
s = Solution()
print(s.wordPattern("aba", "121"))