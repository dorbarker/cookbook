from Bio import SeqIO

output_sequences = []

with open('data/gapped_alignment.fasta', 'r') as f:

    all_sequences = list(SeqIO.parse(f, 'fasta'))

length_with_gaps = len(all_sequences[0].seq)

mask = [True for _ in range(length_with_gaps)]

for record in all_sequences:

    # Set mask element to False if any sequence
    # has a gap at that position
    for position, (bit, nt) in enumerate(zip(mask, record.seq)):

        mask[position] = bit and nt != '-'

for record in all_sequences:

    name = record.id

    _, chars = zip(*filter(lambda x: x[0], zip(mask, record.seq)))

    output_sequence = ''.join(chars)

    output_record = f'>{name}\n{output_sequence}'

    output_sequences.append(output_record)

output_mfa = '\n'.join(output_sequences)

print(output_mfa)
