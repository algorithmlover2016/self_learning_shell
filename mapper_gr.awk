#!/usr/bin/awk -f
BEGIN {
    split(get_modules(), module_list, " ");
    # sampling number of record
    sample_nr = 1;
    # sampling base, 每matched 40行抽取一条，与sia策略保持一致
    sample_base = 40;
    # 最小耗时
    min_cost_ms = 0;
    # 最大耗时
    max_cost_ms = 10000;
}
{
    # global filter
    if ($0 !~ /.*command:feed.*response detail infos/) {
        next;
    }

    # 抽样策略与目前sia保持一致
    if (sample_nr++ % sample_base != 1) {
        next;
    }

    for (i in module_list) {
        key = find_key($0, module_list[i]);
        # Not found
        if (key == "" ) {
            continue;
        }
        # filter unexpected case ex: [cube_cost_ms:-1
        # 字符串转换为int，否则是字符ASSIC码的比较
        val = int(substr(key, index(key, ":")+1));
        if (val < min_cost_ms || val > max_cost_ms) {
            continue;
        }
        # Keep the left [
        found[key]++; 
    }
}
END {
    for (i in found) {
        print i" "found[i];
    }
}

# My functions
function find_key(line, module) {
    item  = "["module":"; # ex: [cost_ms: / [sid:
    start = index(line, item);
    if (start == 0) { # Not found
        return "";
    }
    word = substr(line, start);
    key  = substr(word, 1, index(word, "]")-1);
    return key;
}
function get_modules() {
    # cmd = "readlink -f $PWD";
    # cmd | getline xx;
    # print xx;
    cmd = "echo $TAG_PATH";
    cmd | getline basedir;
    tagfile = basedir"/grlog";
    # \需要双转义
    cmd = "cat "tagfile"|grep -v '^$'|sed 's/\\s\\+//g'|xargs";
    cmd | getline modules;
    return modules;
}