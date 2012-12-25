# -*- coding:utf-8 -*-
'''
hierarchy_tree

Created on Dec 20, 2012
@author: ray
'''
import os
import csv
import networkx as nx


def read_hierarchy():
    with open('/home/ray/relativity.csv', 'rb') as fp:
        reader = csv.DictReader(fp, delimiter=';')
        for record in reader:
            yield record['base_id'], record['over_id']


def write_dot(g, filename):
    A = nx.to_agraph(g)
    A.layout(prog='dot')
    A.draw(filename)


def write_png(g, filename):
    A = nx.to_agraph(g)
    A.layout(prog='dot')
    A.draw(filename)


def write_csv(g, filename):
    pos = nx.graphviz_layout(g, prog='dot')
    with open(filename, 'wb') as fp:
        writer = csv.writer(fp)

        order = set()
        for node_id, (x, y) in pos.items():
            order.add(y)

        order = list(order)
        order.sort(reverse=True)
        print order
        for node_id, (x, y) in pos.items():
            record_order = order.index(y)
            if not g.in_edges(node_id):
                record_order = 0
            writer.writerow((node_id, x, y, record_order))


def check_cyclic(g, result):
    for n, subgraph in enumerate(nx.weakly_connected_component_subgraphs(g)):
        h = nx.flow_hierarchy(subgraph)
        if h != 1:
            print nx.simple_cycles(subgraph)
            write_png(subgraph, os.path.join(result, '%s.png' % n))


def main():

    g = nx.DiGraph()
    for n, (base_id, over_id) in enumerate(read_hierarchy()):
        if not base_id or not over_id:
            continue
#        if n == 20:
#            break
        g.add_edge(base_id, over_id)


#    check_cyclic(g, '/home/ray/check_cyclic/')
#    write_dot(g, '/home/ray/test.dot')
#    write_png(g, '/home/ray/test.png')
    write_csv(g, '/home/ray/hierarchy.csv')

if __name__ == '__main__':
    main()
